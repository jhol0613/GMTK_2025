extends FmodBankLoader

@export var bpm: float
##Should be a multiple of 2 to avoid strange results
@export var time_multiplier := Enums.TimeMultiplier.SINGLE: set = _time_multiplier_changed
		
@onready var beat_time_seconds := 60.0/bpm
@onready var music_event = $MusicEvent

signal music_bar

# Parameter values for music modes
@onready var _mode_dictionary = {
	Enums.MusicMode.MENU: 0.0,
	Enums.MusicMode.THINKING: 0.5,
	Enums.MusicMode.RUNNING: 1.0
}

# Ensure time change only happens on a beat that makes sense in the new time
@onready var _bar := 0

func _on_music_event_timeline_beat(_params: Dictionary) -> void:
	
	if _params.get("bar") == _bar:
		return
	_bar = _params.get("bar")
	
	if _bar % time_multiplier == 1:
		music_bar.emit()
		
func _time_multiplier_changed(new_multiplier: Enums.TimeMultiplier):
	time_multiplier = new_multiplier
	beat_time_seconds = 60.0 * time_multiplier / (bpm * 4.0)

func set_music_mode(mode: Enums.MusicMode):
	music_event.set_parameter("ThinkingMode", _mode_dictionary.get(mode))
