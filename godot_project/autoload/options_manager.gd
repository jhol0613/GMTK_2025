extends Node


const OPTIONS_DATA_PATH := "user://options_data.tres"
const MUSIC_PARAMETER_FMOD := "Music_Vol"
const SFX_PARAMETER_FMOD := "SFX_Vol"

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
	FmodServer.set_global_parameter_by_name(MUSIC_PARAMETER_FMOD, options_data.music_value)
	FmodServer.set_global_parameter_by_name(SFX_PARAMETER_FMOD, options_data.sfx_value)

func commit():
	if not options_data:
		options_data = OptionsData.new()
	ResourceSaver.save(options_data, OPTIONS_DATA_PATH)

func set_fullscreen(toggle_on := true):
	options_data.fullscreen = toggle_on
	_sync()

func set_music_value(value := 1.0):
	options_data.music_value = value
	_sync()

func set_sfx_value(value := 1.0):
	options_data.sfx_value = value
	_sync()

func _exit_tree() -> void:
	commit()
