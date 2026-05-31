extends Control

class_name ChangeTreadmillDirectionScreenV2

@export var _rotate_buttons: RotateButtons

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rotate_buttons.direction_pressed.connect(_on_direction_pressed)

func _on_direction_pressed(direction: Enums.Direction):
	direction_pressed.emit(direction)

func set_limits(left_stop: int, right_stop: int):
	_rotate_buttons.set_limits(left_stop, right_stop)

func reset():
	_rotate_buttons.reset()
