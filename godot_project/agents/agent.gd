extends Node2D

class_name Agent

#region Exports

@export_subgroup("Movement curves")
## The curve the agent should follow moving from one tile to another
@export var direct_movement_curve: Curve
## The y value the agent should add to their movement as they move to another tile (to add a "jumping" component instead of just linear motion)
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

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D

@export_subgroup("Sound")
## How long to wait after sequencer signal to start an animation
@export var beat_delays: Dictionary[Enums.PlayerAction, float]

#endregion

@onready var _sprite_default_y = sprite.position.y
@onready var _timer = Timer.new()
# agent's position inside of the grid
var grid_position := Vector2i(0, 0)
# grid's tile size for calculating the local position
var tile_size: Vector2i
# agent's initial position in the grid
var grid_origin := Vector2i.ZERO
# grid origin in local coordinate space to calculate local grid cell position
var local_origin := Vector2.ZERO
# grid total size
var grid_size := Vector2i.ZERO

var follow_on_animation: String

signal action_executed(action: Enums.PlayerAction)

func _ready():
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_beat)
	position = _grid_to_local(grid_origin)

func execute_action(action : Enums.PlayerAction) -> void:
	match action:
		Enums.PlayerAction.UP:
			grid_position += Vector2i.UP
		Enums.PlayerAction.DOWN:
			grid_position += Vector2i.DOWN
		Enums.PlayerAction.LEFT:
			grid_position += Vector2i.LEFT
		Enums.PlayerAction.RIGHT:
			grid_position += Vector2i.RIGHT
	action_executed.emit(action)

	# stupid timer can't rebind the function
	_timer.timeout.disconnect(_on_beat)
	_timer.stop()
	_timer.timeout.connect(_on_beat.bind(action))
	_timer.start(_get_delay_seconds(action))


func _on_beat(action: Enums.PlayerAction) -> void:
	var animation_name = _get_animation_name(action)
	if animation_name != "":
		sprite.play(animation_name)

	if follow_on_animations.get(action) != null:
		follow_on_animation = follow_on_animations.get(action)
		sprite.animation_finished.connect(_on_animation_finished)

	if _is_action_bonk(action):
		# Bonk target is where the player tried to go
		var bonk_target = _grid_to_local(_get_bonk_target(action))
		_initiate_bonk(bonk_target)
	elif action == Enums.PlayerAction.JUMP:
		_initiate_jump()
	elif action != Enums.PlayerAction.NONE:
		_initiate_move(_grid_to_local(grid_position))


func _on_animation_finished():
	sprite.play(follow_on_animation)
	sprite.animation_finished.disconnect(_on_animation_finished)

func reset() -> void:
	if default_animation != "":
		sprite.play(default_animation)
	grid_position = grid_origin
	position = _grid_to_local(grid_position)


func _initiate_move(new_target : Vector2):
	var tween = create_tween()
	tween.tween_method(_move_callback.bind(position, new_target), 0.0, 1.0, move_duration)

func _initiate_bonk(attempted_target: Vector2):
	var tween = create_tween()
	tween.tween_method(_bonk_callback.bind(position, attempted_target), 0.0, 1.0, move_duration)

func _initiate_jump():
	var tween = create_tween()
	tween.tween_method(_jump_callback.bind(), 0.0, 1.0, jump_duration)

func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)


func _move_callback(alpha: float, start_position: Vector2, target_position: Vector2):
	var position_difference = target_position - start_position
	position = direct_movement_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _sprite_default_y

func _bonk_callback(alpha: float, start_position: Vector2, attempted_position: Vector2):
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
