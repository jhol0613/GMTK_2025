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
	if music_event.event_name != "": #Ensure event has been initialized
		music_event.set_parameter("ThinkingMode", _mode_dictionary.get(mode))
		pass
		
##Note that level transitions rely on game over music actually playing, or the transition will hang. Ensure GameOver
##is a valid parameter and properly transitions to the music event ending
func play_world_complete_music():
	if music_event.event_name != "":
		music_event.set_parameter("GameOver", 1.0)
	
func play_music_event(event_name: String, new_bpm: float):
	if music_event.get_parameter("GameOver") != null:
		music_event.set_parameter("GameOver", 0.0)
	music_event.stop()
	music_event.event_name = "event:/" + event_name
	bpm = new_bpm
	bpm_changed.emit(bpm)
	music_event.play()
	
func on_music_stopped():
	music_complete.emit()

func get_fps_from_bpm():
	return bpm / 30.0
