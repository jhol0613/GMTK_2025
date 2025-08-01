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
@export var shadow: Sprite2D
@export var sprite: AnimatedSprite2D

#endregion

@onready var _sprite_default_y = sprite.position.y
var grid_position := Vector2i(0, 0)
var tile_size: Vector2i

signal action_executed(action: Enums.PlayerAction)

func _ready():
	for anim_name in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.set_animation_speed(anim_name, frame_rate)

func execute_action(action : Enums.PlayerAction) -> void:
	var new_position := shadow.global_position
	match action:
		Enums.PlayerAction.UP:
			new_position += Vector2.UP * tile_size.y
		Enums.PlayerAction.DOWN:
			new_position += Vector2.DOWN * tile_size.y
		Enums.PlayerAction.LEFT:
			new_position += Vector2.LEFT * tile_size.x
		Enums.PlayerAction.RIGHT:
			new_position += Vector2.RIGHT * tile_size.x
	action_executed.emit(action)

	var animation_name = _get_animation_name(action)
	if animation_name != null:
		sprite.play(animation_name)

	_initiate_move(new_position)


func _initiate_move(new_target : Vector2):
	var tween = create_tween()
	tween.tween_method(_move_callback.bind(shadow.global_position, new_target), 0.0, 1.0, move_duration)


func _move_callback(alpha: float, start_position: Vector2, target_position: Vector2):
	var position_difference = target_position - start_position
	shadow.global_position = direct_movement_curve.sample(alpha) * position_difference + start_position
	sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _sprite_default_y


func _get_animation_name(action: Enums.PlayerAction) -> String:
	return animations.get(action, null)
