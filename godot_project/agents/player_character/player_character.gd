extends Node2D

@export var tile_width : int
@export var tile_height : int

var grid_posit : Vector2i

func _ready() -> void:
	pass
	
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Left"):
		move_left()
	if event.is_action_pressed("Right"): 
		move_right()
	if event.is_action_pressed("Up"): 
		move_up()
	if event.is_action_pressed("Down"): 
		move_down()
	
func move_left() -> void:
	grid_posit.x -= 1
	pass
	
func move_right() -> void:
	grid_posit.x += 1
	pass
	
func move_up() -> void:
	pass
	
func move_down() -> void:
	pass
	
	
