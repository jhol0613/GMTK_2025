extends Node2D

class_name DigipadMove

@export var _buttons : Array[DirectionButton]

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button in _buttons:
		button.pressed_direction.connect(_on_button_pressed)

func _on_button_pressed(direction: Enums.Direction):
	direction_pressed.emit(direction)
