extends Node


const OPTIONS_DATA_PATH := "user://options_data.tres"

var options_data: OptionsData

func _ready() -> void:
	if not FileAccess.file_exists(OPTIONS_DATA_PATH):
		commit()
	else:
		options_data = ResourceLoader.load(OPTIONS_DATA_PATH)

	_sync()

func _sync():
	if options_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func commit():
	if not options_data:
		options_data = OptionsData.new()
	ResourceSaver.save(options_data, OPTIONS_DATA_PATH)

func set_fullscreen(toggle_on := true):
	options_data.fullscreen = toggle_on
	_sync()

func _exit_tree() -> void:
	commit()
