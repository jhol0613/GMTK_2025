extends FmodBankLoader

var _beat = 0

signal music_bar
signal music_beat(beat: int)

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
