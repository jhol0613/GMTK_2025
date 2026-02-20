extends Node2D

class_name Digipad

@export var button_group: ButtonGroup

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button in button_group.get_buttons():
		button.pressed.connect(_on_button_pressed)
	pass # Replace with function body.

func _on_button_pressed():
	direction_pressed.emit(button_group.get_pressed_button().direction)

#func _on_up_pressed() -> void:
	#direction_pressed.emit(Enums.Direction.UP)
 #
#func _on_left_pressed() -> void:
	#direction_pressed.emit(Enums.Direction.LEFT)
#
#func _on_down_pressed() -> void:
	#direction_pressed.emit(Enums.Direction.DOWN)
#
#func _on_right_pressed() -> void:
	#direction_pressed.emit(Enums.Direction.RIGHT)
#
#func _deselect_buttons_except(direction: Enums.Direction):
	#pass
	
