extends FmodBankLoader

var _beat = 0

@export var bpm: float
@onready var beat_time_seconds := 60.0/bpm

@onready var music_event = $MusicEvent

signal music_bar
signal music_beat(beat: int)

# Parameter values for music modes
var _thinking_mode = .5
var _running_mode = 1.0
var _title_mode = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_event.set_parameter("ThinkingMode", _running_mode)
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
