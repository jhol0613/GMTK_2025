extends Control

class_name ChangeTreadmillDirectionScreen

@export var digipad: Digipad

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	digipad.direction_pressed.connect(_on_direction_pressed)

func _on_direction_pressed(direction: Enums.Direction):
	direction_pressed.emit(direction)
