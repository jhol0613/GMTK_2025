extends Interactable

class_name HideBench

# Number of actions to hide
@export var hide_duration := 3

@onready var sound_open := $FmodEventEmitter2D
@onready var sound_close := $FmodEventEmitter2D2

var hiding := false
var beats_hidden := 0

signal started_hiding
signal finished_hiding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	connect("interaction_succeeded", _on_interaction_succeeded)

func _on_interaction_succeeded():
	#AudioManager.music_bar.connect(_on_music_bar)
	if hiding:
		_finish_hiding()
	else:
		_start_hiding()
	#beats_hidden = 0
	
	
func _start_hiding():
	sound_open.play()
	player_animation_on_success = "unhide"
	follow_on_animation_on_success = "idle_down"
	hiding = true
	started_hiding.emit()

func _finish_hiding():
	sound_close.play()
	player_animation_on_success = "hide"
	follow_on_animation_on_success = "hiding"
	hiding = false
	finished_hiding.emit()
	
#func _on_music_bar():
	#beats_hidden += 1
	#if beats_hidden >= hide_duration:
		#finished_hiding.emit()
		#hiding = false
		#AudioManager.music_bar.disconnect(_on_music_bar)
