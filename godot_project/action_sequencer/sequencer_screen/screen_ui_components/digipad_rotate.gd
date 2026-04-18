extends Node2D

class_name DigipadRotate

@export var button_group: ButtonGroup

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button in button_group.get_buttons():
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	direction_pressed.emit(button_group.get_pressed_button().direction)
