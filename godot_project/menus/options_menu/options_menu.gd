extends Control

class_name OptionsMenu

@onready
var fullscreen_checkbox = $FullscreenOption/CheckButton

func _ready() -> void:
	fullscreen_checkbox.set_pressed_no_signal(OptionsManager.options_data.fullscreen)

func _process(delta: float) -> void:
	var mode := DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_FULLSCREEN
	]

	if mode != OptionsManager.options_data.fullscreen:
		OptionsManager.set_fullscreen(mode)
		fullscreen_checkbox.set_pressed_no_signal(
			OptionsManager.options_data.fullscreen
		)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	OptionsManager.set_fullscreen(toggled_on)
