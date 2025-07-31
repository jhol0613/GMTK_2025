extends Node2D

class_name PlayerCharacter

## The curve the player should follow moving from one tile to another
@export var direct_movement_curve: Curve
## The y value the player should add to their movement as they move to another tile (to add a "jumping" component instead of just linear motion)
@export var y_movement_curve: Curve
@export var y_movement_magnitude := 32.0

## Distance (in pixels) from one tile to the one above or below it
@export var vertical_action_distance: int
## Distance (in pixels) from one tile to the one to the one left or right of it
@export var horizontal_action_distance: int
## Amount of time for movement animation
@export var move_duration := .3

@onready var _shadow := $Shadow
@onready var _player_sprite := $Shadow/PlayerSprite
@onready var _player_sprite_default_y = _player_sprite.position.y

func _ready() -> void:
	pass
	
func _process(delta) -> void:
	pass
	
func execute_action(action : Enums.PlayerAction) -> void:
	match action:
		Enums.PlayerAction.UP:
			_move_up()
		Enums.PlayerAction.DOWN:
			_move_down()
		Enums.PlayerAction.LEFT:
			_move_left()
		Enums.PlayerAction.RIGHT:
			_move_right()

#region PlayerActions

func _move_left() -> void:
	_initiate_move(_shadow.global_position + Vector2(-horizontal_action_distance, 0))
	
func _move_right() -> void:
	_initiate_move(_shadow.global_position + Vector2(horizontal_action_distance, 0))
	
func _move_up() -> void:
	_initiate_move(_shadow.global_position + Vector2(0, -vertical_action_distance))
	
func _move_down() -> void:
	_initiate_move(_shadow.global_position + Vector2(0, vertical_action_distance))
	
#endregion

func _initiate_move(new_target : Vector2):
	var tween = create_tween()
	tween.tween_method(_move_callback.bind(_shadow.global_position, new_target), 0.0, 1.0, move_duration)
	
func _move_callback(alpha: float, start_position: Vector2, target_position: Vector2):
	var position_difference = target_position - start_position
	_shadow.global_position = direct_movement_curve.sample(alpha) * position_difference + start_position
	_player_sprite.position.y = -y_movement_curve.sample(alpha) * y_movement_magnitude + _player_sprite_default_y
	print(direct_movement_curve.sample(alpha))
	print("called move callback", global_position)
