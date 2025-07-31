extends Node2D

class_name PlayerCharacter

## The curve the player should follow moving from one tile to another
@export var directy_movement_curve: Curve
## The y value the player should add to their movement as they move to another tile (to add a "jumping" component instead of just linear motion)
@export var y_movement_curve: Curve

## Distance (in pixels) from one tile to the one above or below it
@export var vertical_action_distance: int
## Distance (in pixels) from one tile to the one to the one left or right of it
@export var horizontal_action_distance: int

func _ready() -> void:
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
	print("moved left!")
	
func _move_right() -> void:
	print("moved right!")
	
func _move_up() -> void:
	print("moved up!")
	
func _move_down() -> void:
	print("moved down!")
	
#endregion
