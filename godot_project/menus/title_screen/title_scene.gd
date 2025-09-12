extends Control

@export_subgroup("Animation")
@export var train_dip_time := .08
@export var dip_beats := [2,6,8]
@export var cycle_length := 16

@onready var _title = $Title
@onready var _hover_emitter = $HoverEmitter
@onready var _click_start_emitter = $ClickStartEmitter
@onready var _track_sprite = $Title/TrackSprite

@onready var _num_track_frames = _track_sprite.sprite_frames.get_frame_count("default")


var _beat := 0


func _ready():
	pass
#	AudioManager.connect("music_beat", _on_music_beat)

func _on_play_pressed() -> void:
	GameManager.load_scene(Enums.Scenes.INTRO_CUTSCENE)


func _on_music_beat(beat: int):
	_track_sprite.frame = (_track_sprite.frame + 1) % _num_track_frames
	_beat = beat
	if _beat % cycle_length in dip_beats:
		_title.frame = 1
		await get_tree().create_timer(train_dip_time).timeout
		_title.frame = 0

func _on_play_mouse_entered() -> void:
	_hover_emitter.play()


func _on_options_mouse_entered() -> void:
	_hover_emitter.play()


func _on_play_button_down() -> void:
	_click_start_emitter.play()


func _on_options_button_down() -> void:
	_click_start_emitter.play()
	
	
func _on_quit_pressed() -> void:
	get_tree().quit()
