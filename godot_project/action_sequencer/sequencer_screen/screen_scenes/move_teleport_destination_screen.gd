extends Control

class_name MoveTeleporterDestinationScreen

@export var digipad: DigipadCycle

signal option_cycled(index: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	digipad.option_cycled.connect(_on_option_cycled)

func _on_option_cycled(index: int):
	option_cycled.emit(index)
