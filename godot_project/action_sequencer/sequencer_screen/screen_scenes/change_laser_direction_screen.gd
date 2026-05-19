extends Control

class_name ChangeLaserDirectionScreen

@export var digipad: DigipadRotate

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	digipad.direction_pressed.connect(_on_direction_pressed)

func _on_direction_pressed(direction: Enums.Direction):
	direction_pressed.emit(direction)

func set_allowed_directions(allowed_directions: Array[Enums.Direction]):
	digipad._set_allowed_directions(allowed_directions)
