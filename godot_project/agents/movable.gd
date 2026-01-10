extends Agent

class_name Movable

#region Exports

@export_subgroup("Movement Curve Data")
## Curve and timing data for standard moves (up, down, left, and right)
@export var standard_move_data: MovableActionData
## Curve and timing data for bonks (bonk up, bonk down, bonk left, bonk right)
@export var bonk_data: MovableActionData
## Curve and timing for slides
@export var slide_data: MovableActionData
## Curve and timing for slide bonks
@export var slide_bonk_data: MovableActionData
## Curve and movement data for any additional actions that the movable will use
@export var other_action_data: Dictionary[Enums.PlayerAction, MovableActionData]

@export_subgroup("Nodes")
##If this is set, this area will jump out ahead at the start of the move before animation visuals catch up
@export var collision_area: Area2D
# local position of collision area
var _collision_area_initial_position
#endregion

@onready var _sprite_default_y = sprite.position.y

##Null curve for when curve not specified
@onready var null_curve = Curve.new()

##Timer for delaying move to desired beat
@onready var _movement_timer = Timer.new()


# Allows collision to move immediately while visuals catch up
var _frozen_collision_position_during_move: Vector2i

# If reset in middle of a move
var _moving_tween: Tween

func _ready():
	super._ready()
	add_to_group("movables")
	
	_movement_timer.one_shot = true
	_movement_timer.autostart = false
	add_child(_movement_timer)
	#_movement_timer.timeout.connect(_on_movement_start)
	
	null_curve.add_point(Vector2(0,0))
	null_curve.add_point(Vector2(1,0))
	#tick.connect(_on_sequencer_beat)
	#action_executed.connect(_on_action_executed)
	if collision_area != null:
		_collision_area_initial_position = collision_area.position

func execute_action(action : Enums.PlayerAction, beat: int, skip_animation := false) -> void:
	super.execute_action(action, beat, skip_animation)
	if not check_activation_for_beat(beat):
		return
	var action_data: MovableActionData
	var should_move_collision := false
	var move_target := grid_position + Enums.player_action_to_vector(action)
	
	if action == Enums.PlayerAction.NONE:
		return

	if Enums.is_action_move(action):
		action_data = standard_move_data
		should_move_collision = true
	elif Enums.is_action_bonk(action):
		action_data = bonk_data
		move_target = _get_bonk_target(action)
	elif Enums.is_action_slide(action):
		action_data = slide_data
		should_move_collision = true
	elif Enums.is_action_slide_bonk(action):
		action_data = slide_bonk_data
		move_target = _get_bonk_target(action)
	else:
		if Enums.is_action_fall(action):
			should_move_collision = true
		action_data = other_action_data.get(action)
	if !action_data:
		push_error("Attempting to call an action on a movable that doesn't have defined data for that action")
		return
	
	# Reset collision position if it's defined
	if collision_area == null:
		should_move_collision = false
	else:
		collision_area.position = _collision_area_initial_position
	
	var move_delay = action_data.timing_offset + action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds
	_execute_callable_on_timer(_movement_timer, move_delay, _on_movement_start.bind(action, move_target, action_data, should_move_collision))

# move_target is where the agent is moving, or where it attempted to move (i.e. bonk)
func _on_movement_start(action: Enums.PlayerAction, move_target: Vector2i, action_data: MovableActionData, should_move_collision: bool):
	# Grid position not updated until movement actually executed on the target beat
	grid_position += Enums.player_action_to_vector(action)
	var move_target_local_space = _grid_to_local(move_target)
	
	if collision_area != null:
		_frozen_collision_position_during_move = collision_area.global_position +  \
		float(should_move_collision) * (move_target_local_space - position)
	
	_moving_tween = create_tween()
	_moving_tween.tween_method(_action_movement_callback.bind(position, move_target_local_space, action_data.direct_movement_curve, 
		action_data.y_movement_curve, action_data.y_movement_magnitude), 0.0, 1.0, action_data.move_duration)
	
func _action_movement_callback(alpha: float, start_position: Vector2, target_position: Vector2, \
	move_curve: Curve = null_curve, y_curve: Curve = null_curve, y_magnitude: float = 16.0):
	
	if collision_area != null:
		collision_area.global_position = _frozen_collision_position_during_move
	var position_difference = target_position - start_position
	position = move_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_curve.sample(alpha) * y_magnitude + _sprite_default_y

func reset():
	if _moving_tween:
		_moving_tween.kill()
	_reset_timer(_movement_timer)
	if _sprite_default_y:
		sprite.position.y = _sprite_default_y
	super.reset()

func interrupt_queued_action(should_cancel_sound := true):
	super.interrupt_queued_action(should_cancel_sound)
	if _movement_timer.is_connected("timeout", _on_movement_start):
		_movement_timer.disconnect("timeout", _on_movement_start)

func _get_bonk_target(action: Enums.PlayerAction) -> Vector2i:
	var attempted_position: Vector2i
	match action:
		Enums.PlayerAction.UP_BONK, Enums.PlayerAction.UP_SLIDE_BONK:
			attempted_position = grid_position + Vector2i.UP
		Enums.PlayerAction.DOWN_BONK, Enums.PlayerAction.DOWN_SLIDE_BONK:
			attempted_position = grid_position + Vector2i.DOWN
		Enums.PlayerAction.LEFT_BONK, Enums.PlayerAction.LEFT_SLIDE_BONK:
			attempted_position = grid_position + Vector2i.LEFT
		Enums.PlayerAction.RIGHT_BONK, Enums.PlayerAction.RIGHT_SLIDE_BONK:
			attempted_position = grid_position + Vector2i.RIGHT
		_:
			attempted_position = grid_position + Vector2i.ZERO

	return attempted_position


#func _get_animation_name(action: Enums.PlayerAction) -> String:
	#return animations.get(action, "")


func _is_action_bonk(action: Enums.PlayerAction):
	return (action == Enums.PlayerAction.LEFT_BONK) or \
		(action == Enums.PlayerAction.RIGHT_BONK) or \
		(action == Enums.PlayerAction.UP_BONK) or \
		(action == Enums.PlayerAction.DOWN_BONK)
