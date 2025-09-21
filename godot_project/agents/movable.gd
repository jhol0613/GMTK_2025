extends Agent

class_name Movable

#region Exports

@export_subgroup("Movement curves")
## The curve the movable should follow moving from one tile to another
@export var direct_movement_curve: Curve
## The y value the movable should add to their movement as they move to another tile (to add a "jumping" component instead of just linear motion)
@export var y_movement_curve: Curve
@export var y_movement_magnitude := 16.0
@export var bonk_curve: Curve
@export var jump_curve: Curve
@export var jump_magnitude := 24.0
@export var jump_duration := .53

@export_subgroup("Frames")
## Amount of time for movement animation
@export var move_duration := .3
## Animation names from the animated sprite for actions
@export var animations: Dictionary[Enums.PlayerAction, String]
## If a follow-on animation is defined for a given action, that animation will play after an action animation is finished
@export var follow_on_animations: Dictionary[Enums.PlayerAction, String]
@export var default_animation: String

@export_subgroup("Sound")
## How long to wait after sequencer signal to start an animation
@export var beat_delays: Dictionary[Enums.PlayerAction, float]
## Sound emitter for each action
@export var sound_emitters: Dictionary[Enums.PlayerAction, FmodEventEmitter2D]

@export_subgroup("Nodes")
@export var collision_area: Area2D
# local position of collision area
var _collision_area_initial_position
#endregion

@onready var _sprite_default_y = sprite.position.y
##Timer for delaying action to desired beat
@onready var _timer = Timer.new()


var follow_on_animation: String
var currently_playing_emitter: FmodEventEmitter2D

# Allows collision to move immediately while visuals catch up
var _frozen_collision_position_during_move: Vector2i

signal action_executed(action: Enums.PlayerAction)

func _ready():
	super._ready()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_beat)
	if collision_area != null:
		_collision_area_initial_position = collision_area.position

func execute_action(action : Enums.PlayerAction) -> void:

	
	if collision_area != null:
		#collision_area.top_level = false
		collision_area.position = _collision_area_initial_position
	
	currently_playing_emitter = sound_emitters.get(action, null)
	if currently_playing_emitter:
		currently_playing_emitter.play()

	if _get_delay_seconds(action) == 0.0:
		_on_beat(action)
	else:
		# stupid timer can't rebind the function
		if _timer.is_connected("timeout", _on_beat):
			_timer.timeout.disconnect(_on_beat)
		_timer.stop()
		_timer.timeout.connect(_on_beat.bind(action))
		_timer.start(_get_delay_seconds(action))

func play_animation(animation_name: String, follow_on = null):
	assert(sprite.sprite_frames.get_animation_names().has(animation_name), "Attemtping to call play movable animation that does not exisst")
	sprite.play_with_signals(animation_name)
	if follow_on != null:
		follow_on_animation = follow_on
		if not sprite.animation_finished.has_connections():
			sprite.animation_finished.connect(_on_animation_finished)

## Called on the beat when the action starts visually (as opposed to sequencer signal)
func _on_beat(action: Enums.PlayerAction) -> void:
		
	match action:
		Enums.PlayerAction.UP, Enums.PlayerAction.UP_FALL:
			grid_position += Vector2i.UP
		Enums.PlayerAction.DOWN, Enums.PlayerAction.DOWN_FALL:
			grid_position += Vector2i.DOWN
		Enums.PlayerAction.LEFT, Enums.PlayerAction.LEFT_FALL:
			grid_position += Vector2i.LEFT
		Enums.PlayerAction.RIGHT, Enums.PlayerAction.RIGHT_FALL:
			grid_position += Vector2i.RIGHT
	action_executed.emit(action)

	var animation_name = _get_animation_name(action)
	if animation_name != "":
		play_animation(animation_name, follow_on_animations.get(action))

	if _is_action_bonk(action):
		# Bonk target is where the player tried to go
		var bonk_target = _grid_to_local(_get_bonk_target(action))
		_initiate_bonk(bonk_target)
	elif action == Enums.PlayerAction.JUMP:
		_initiate_jump()
	elif action != Enums.PlayerAction.NONE:
		_initiate_move(_grid_to_local(grid_position))

func interrupt_queued_action():
	if _timer.is_connected("timeout", _on_beat):
		_timer.disconnect("timeout", _on_beat)
	_timer.stop()
	
	if currently_playing_emitter:
		currently_playing_emitter.stop()

func _on_animation_finished():
	sprite.play_with_signals(follow_on_animation)
	sprite.animation_finished.disconnect(_on_animation_finished)

func reset() -> void:
	super.reset()
	#_should_interrupt_queued_action = false
	if default_animation != "":
		sprite.play_with_signals(default_animation)

func _initiate_move(new_target : Vector2):
	# First move collision area instantly out ahead, then freeze in place while movable visuals catch up
	if collision_area != null:
		_frozen_collision_position_during_move = collision_area.global_position + (new_target - position)
		#collision_area.top_level = true
	var tween = create_tween()
	tween.tween_method(_move_callback.bind(position, new_target), 0.0, 1.0, move_duration)

func _initiate_bonk(attempted_target: Vector2):
	# Keep collision area on current square if you're going to bonk anyway
	if collision_area != null:
		_frozen_collision_position_during_move = collision_area.global_position
	var tween = create_tween()
	tween.tween_method(_bonk_callback.bind(position, attempted_target), 0.0, 1.0, move_duration)

func _initiate_jump():
	var tween = create_tween()
	tween.tween_method(_jump_callback.bind(), 0.0, 1.0, jump_duration)


func _move_callback(alpha: float, start_position: Vector2, target_position: Vector2):
	if collision_area != null:
		collision_area.global_position = _frozen_collision_position_during_move
	var position_difference = target_position - start_position
	position = direct_movement_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _sprite_default_y

func _bonk_callback(alpha: float, start_position: Vector2, attempted_position: Vector2):
	if collision_area != null:
		collision_area.global_position = _frozen_collision_position_during_move
	var position_difference = attempted_position - start_position
	position = bonk_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _sprite_default_y

func _jump_callback(alpha: float):
	sprite.position.y = -jump_curve.sample(alpha) * jump_magnitude + _sprite_default_y

func _get_bonk_target(action: Enums.PlayerAction) -> Vector2i:
	var attempted_position: Vector2i
	match action:
		Enums.PlayerAction.UP_BONK:
			attempted_position = grid_position + Vector2i.UP
		Enums.PlayerAction.DOWN_BONK:
			attempted_position = grid_position + Vector2i.DOWN
		Enums.PlayerAction.LEFT_BONK:
			attempted_position = grid_position + Vector2i.LEFT
		Enums.PlayerAction.RIGHT_BONK:
			attempted_position = grid_position + Vector2i.RIGHT
		_:
			attempted_position = grid_position + Vector2i.ZERO

	return attempted_position


func _get_animation_name(action: Enums.PlayerAction) -> String:
	return animations.get(action, "")


func _get_delay_seconds(action: Enums.PlayerAction) -> float:
	return beat_delays.get(action, 0.0) * AudioManager.beat_time_seconds

func _is_action_bonk(action: Enums.PlayerAction):
	return (action == Enums.PlayerAction.LEFT_BONK) or \
		(action == Enums.PlayerAction.RIGHT_BONK) or \
		(action == Enums.PlayerAction.UP_BONK) or \
		(action == Enums.PlayerAction.DOWN_BONK)
