extends Control

class_name OptionsMenu

@onready
var fullscreen_checkbox = $FullscreenOption/CheckButton

func _ready() -> void:
	fullscreen_checkbox.set_pressed_no_signal(OptionsManager.fullscreen)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	OptionsManager.set_fullscreen(toggled_on)
