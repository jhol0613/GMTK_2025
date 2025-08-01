extends FmodBankLoader

var _beat = 0

@export var bpm: float
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_music_event_timeline_beat(params: Dictionary) -> void:
	if _beat < 4:
		_beat += 1
	else:
		_beat = 1
		music_bar.emit()
	music_beat.emit(_beat)
	pass # Replace with function body.
	
func set_music_mode(mode: Enums.MusicMode):
	music_event.set_parameter("ThinkingMode", _mode_dictionary.get(mode))
