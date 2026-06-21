extends Resource

class_name OptionsData

@export var fullscreen: bool = false
@export var resolution: Enums.Resolution = Enums.Resolution.DEFAULT

func _init(_fullscreen: bool = false, _resolution: Enums.Resolution = Enums.Resolution.DEFAULT):
	fullscreen = _fullscreen
	resolution = _resolution
