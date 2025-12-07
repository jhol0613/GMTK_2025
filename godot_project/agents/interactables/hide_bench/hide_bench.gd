extends Interactable

class_name HideBench

# Number of actions to hide
@export var hide_duration := 3

var hiding := false
var beats_hidden := 0

signal started_hiding
signal finished_hiding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	connect("interaction_succeeded", _on_interaction_succeeded)

func _on_interaction_succeeded():
	AudioManager.music_bar.connect(_on_music_bar)
	started_hiding.emit()
	hiding = true
	beats_hidden = 0
	
func _on_music_bar():
	beats_hidden += 1
	if beats_hidden >= hide_duration:
		finished_hiding.emit()
		hiding = false
		AudioManager.music_bar.disconnect(_on_music_bar)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
