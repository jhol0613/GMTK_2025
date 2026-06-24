extends Resource

class_name OptionsData

@export var fullscreen: bool = false
@export var music_value: float = 0.7
@export var sfx_value: float = 0.7
@export var resolution: Enums.Resolution = Enums.Resolution.DEFAULT

func _init(_fullscreen: bool = false, _music_value: float = 0.7, _sfx_value: float = 0.7, _resolution: Enums.Resolution = Enums.Resolution.DEFAULT):
	fullscreen = _fullscreen
	music_value = _music_value
	sfx_value = _sfx_value
	resolution = _resolution
