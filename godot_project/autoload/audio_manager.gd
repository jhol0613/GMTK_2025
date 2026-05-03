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

@onready var _queue_time_multiplier_update := false
@onready var _queued_multiplier : Enums.TimeMultiplier

func _on_music_event_timeline_beat(_params: Dictionary) -> void:
	if _params.get("bar") == _bar:
		return
	_bar = _params.get("bar")
	
	if _queue_time_multiplier_update:
		if _bar % int((time_multiplier_to_number(_queued_multiplier) * 4)) == 1:
			time_multiplier = _queued_multiplier
			_queue_time_multiplier_update = false

	if _bar % time_multiplier == 1:
		music_bar.emit()

func _time_multiplier_changed(new_multiplier: Enums.TimeMultiplier):
	_queue_time_multiplier_update = true
	time_multiplier = new_multiplier
	beat_time_seconds = 60.0 * time_multiplier / (bpm * 4.0)

func update_time_multiplier(new_multiplier: Enums.TimeMultiplier):
	_queue_time_multiplier_update = true
	_queued_multiplier = new_multiplier

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

##Half time is 2, single is 1, double is .5 and quad is .25 
func get_inverse_time_multiplier() -> float:
	match time_multiplier:
		Enums.TimeMultiplier.HALF:
			return 2.0
		Enums.TimeMultiplier.SINGLE:
			return 1.0
		Enums.TimeMultiplier.DOUBLE:
			return 0.5
		Enums.TimeMultiplier.QUADRUPLE:
			return 0.25
		_:
			return 1.0

func time_multiplier_to_number(multiplier: Enums.TimeMultiplier) -> float:
	match multiplier:
		Enums.TimeMultiplier.HALF:
			return 0.5
		Enums.TimeMultiplier.SINGLE:
			return 1.0
		Enums.TimeMultiplier.DOUBLE:
			return 2.0
		Enums.TimeMultiplier.QUADRUPLE:
			return 4.0
		_:
			return 1.0

##Half time is .5, single is 1.0, double is 2.0, quad is 4.0
func get_time_multiplier_number() -> float:
	return time_multiplier_to_number(time_multiplier)
