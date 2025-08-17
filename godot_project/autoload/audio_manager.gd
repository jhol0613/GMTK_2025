extends FmodBankLoader

@export var bpm: float
##Should be a multiple of 2 to avoid strange results
@export var time_multiplier := Enums.TimeMultiplier.SINGLE
@onready var beat_time_seconds := 60.0/bpm

@onready var music_event = $MusicEvent

signal music_bar
signal music_beat(beat: int)

# Parameter values for music modes
@onready var _mode_dictionary = {
	Enums.MusicMode.MENU: 0.0,
	Enums.MusicMode.THINKING: 0.5,
	Enums.MusicMode.RUNNING: 1.0
}

var _beat = 0


func _on_music_event_timeline_beat(_params: Dictionary) -> void:
	if _beat < 4 * time_multiplier:
		_beat += 1
		if _beat % time_multiplier == 1:
			music_beat.emit(_beat)
	else:
		_beat = 1
		music_bar.emit()
		music_beat.emit(_beat)

func set_music_mode(mode: Enums.MusicMode):
	music_event.set_parameter("ThinkingMode", _mode_dictionary.get(mode))
