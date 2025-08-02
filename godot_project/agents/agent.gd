extends Node2D

class_name Agent

#region Exports

@export_subgroup("Movement curves")
## The curve the agent should follow moving from one tile to another
@export var direct_movement_curve: Curve
## The y value the agent should add to their movement as they move to another tile (to add a "jumping" component instead of just linear motion)
@export var y_movement_curve: Curve
@export var y_movement_magnitude := 16.0

@export_subgroup("Frames")
## Amount of time for movement animation
@export var move_duration := .3
@export var frame_rate := 10.0
## Animation names from the animated sprite for actions
@export var animations: Dictionary[Enums.PlayerAction, String]

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D

@export_subgroup("Sound")
@export var beat_delays: Dictionary[Enums.PlayerAction, float]

#endregion

@onready var _sprite_default_y = sprite.position.y
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


signal action_executed(action: Enums.PlayerAction)

func _ready():
	position = _grid_to_local(grid_origin)
	for anim_name in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.set_animation_speed(anim_name, frame_rate)

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

	# beat delay timer
	# TODO: replace this with a scene timer
	await get_tree().create_timer(_get_delay_seconds(action)).timeout

	var animation_name = _get_animation_name(action)
	if animation_name != "":
		sprite.play(animation_name)

	_initiate_move(_grid_to_local(grid_position))


func reset() -> void:
	grid_position = grid_origin
	position = _grid_to_local(grid_position)


func _initiate_move(new_target : Vector2):
	var tween = create_tween()
	tween.tween_method(_move_callback.bind(position, new_target), 0.0, 1.0, move_duration)


func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)


func _move_callback(alpha: float, start_position: Vector2, target_position: Vector2):
	var position_difference = target_position - start_position
	position = direct_movement_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _sprite_default_y


func _get_animation_name(action: Enums.PlayerAction) -> String:
	return animations.get(action, "")


func _get_delay_seconds(action: Enums.PlayerAction) -> float:
	return beat_delays.get(action, 0.0) * AudioManager.beat_time_seconds
