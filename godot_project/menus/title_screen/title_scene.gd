extends Control

@export_subgroup("Animation")
@export var train_dip_time := .08
@export var dip_beats := [2,6,8]
@export var cycle_length := 16

@export_subgroup("Sound")
@export var music_event_name = "Main_Menu_BGM"
@export var music_event_bpm = 170

@onready var _title = $Title
@onready var _hover_emitter = $HoverEmitter
@onready var _click_start_emitter = $ClickStartEmitter
@onready var _track_sprite = $Title/TrackSprite
@onready var _play_button = $VBoxContainer/Play
@onready var _continue_button = $VBoxContainer/Continue
@onready var _map_button = $VBoxContainer/Map

@onready var _num_track_frames = _track_sprite.sprite_frames.get_frame_count("default")


var _beat := 0


func _ready():
	
	if SaveManager.first_play:
		_play_button.visible = true
		_continue_button.visible = false
		_click_start_emitter.visible = false
		_map_button.visible = false
	else:
		_play_button.visible = false
		_continue_button.visible = true
		_click_start_emitter.visible = true
		_map_button.visible = true
	
	
	AudioManager.play_music_event(music_event_name, music_event_bpm, false)

func _on_play_pressed() -> void:
	GameManager.load_scene(Enums.Scenes.LEVEL_MANAGER)

func _on_continue_pressed() -> void:
	GameManager.start_world = SaveManager.save_data.furthest_level_reached["world"]
	GameManager.start_level = SaveManager.save_data.furthest_level_reached["level"]
	GameManager.load_scene(Enums.Scenes.LEVEL_MANAGER)

func _on_map_pressed() -> void: 
	GameManager.load_scene(Enums.Scenes.MAP, Enums.TransitionStyle.FADEINOUT, .2, .3)

func _on_music_beat(beat: int):
	pass
	#_track_sprite.frame = (_track_sprite.frame + 1) % _num_track_frames
	#_beat = beat
	#if _beat % cycle_length in dip_beats:
		#_title.frame = 1
		#await get_tree().create_timer(train_dip_time).timeout
		#_title.frame = 0

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
