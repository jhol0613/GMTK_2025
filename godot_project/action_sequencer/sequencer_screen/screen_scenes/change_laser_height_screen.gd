extends Control

class_name ChangeLaserHeightScreen

@export var slider: HSlider

signal value_updated(new_value: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slider.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: int):
	value_updated.emit(new_value)
