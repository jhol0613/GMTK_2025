extends FmodBankLoader

@export var bpm: float
##Should be a multiple of 2 to avoid strange results
@export var time_multiplier := Enums.TimeMultiplier.SINGLE: set = _time_multiplier_changed
## The amount of time for a single beat in seconds
@onready var beat_time_seconds := 60.0 * time_multiplier / (bpm * 4)
@onready var music_event := $MusicEvent

signal music_bar
signal music_complete
signal bpm_changed(new_bpm: float)

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
	FmodServer.set_global_parameter_by_name("ThinkingMode", _mode_dictionary.get(mode))

##Note that level transitions rely on game over music actually playing, or the transition will hang. Ensure GameOver
##is a valid parameter and properly transitions to the music event ending
func play_world_complete_music():
	FmodServer.set_global_parameter_by_name("GameOver", 1.0)
	#if music_event.event_name != "":
		#music_event.set_parameter("GameOver", 1.0)

func play_music_event(event_name: String, new_bpm: float):
	FmodServer.set_global_parameter_by_name("GameOver", 0.0)
	music_event.stop()
	music_event.event_name = "event:/" + event_name
	bpm = new_bpm
	bpm_changed.emit(bpm)
	music_event.play()

func on_music_stopped():
	music_complete.emit()

## If query bpm is supplied, does the math with that bpm. Otherwise uses current bpm
func get_fps_from_bpm(query_bpm = bpm):
	#divide by 30
	return query_bpm * .0333333333333333

## If query bpm is supplied, does the math with that bpm. Otherwise uses current bpm
func get_bpm_from_fps(query_bpm = bpm):
	return query_bpm * 30.0
