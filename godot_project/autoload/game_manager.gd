extends Node2D

@export_subgroup("Scenes")
@export var scene_dict: Dictionary[Enums.Scenes, PackedScene]
## Scenes must explicitly set pause enabled to true
@export var pause_enabled := false

@export_subgroup("Save Files")
@export var save_file_path := "user://save_data.json"

@export_subgroup("Animation")
@export var default_fade_out_time := 1.0
@export var default_fade_in_time := 1.0

@export_subgroup("Levels")
@export var level_catalog: LevelCatalog
@export var start_world := 0
@export var start_level := 0

@onready var _transition_out_time = default_fade_out_time
@onready var _transition_in_time = default_fade_in_time

@onready var _pause_layer: CanvasLayer

var _save_data: Dictionary

func _ready():
	_load_save_data()
	
func _load_save_data():
	if FileAccess.file_exists(save_file_path):
		var json = JSON.new()
		var json_string = FileAccess.get_file_as_string(save_file_path)
		var error = json.parse(json_string)
		if error == OK:
			if typeof(json.data) == TYPE_DICTIONARY:
				print(json.data)
				_save_data = json.data
	else:
		# Create new save data if it doesn't exist yet
		_save_data = {
			"farthest_level_reached": 0, 
			"collectibles_acquired": []}
		_save_save_data()
		
func _save_save_data():
	var json_string = JSON.stringify(_save_data)
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	print(file.get_open_error())
	file.store_string(json_string)
	file.close()

func load_scene(scene: Enums.Scenes, transition_style = Enums.TransitionStyle.FADEINOUT, transition_in_time = default_fade_in_time,
	transition_out_time = default_fade_out_time):

	_transition_out_time = transition_out_time
	_transition_in_time = transition_in_time
	
	pause_enabled = false

	match transition_style:
		Enums.TransitionStyle.FADEINOUT:
			_fadeout(scene)
		Enums.TransitionStyle.NONE:
			_load_scene(scene)

func pause_game():
	if pause_enabled:
		get_tree().paused = true
		_pause_layer = CanvasLayer.new()
		_pause_layer.layer = 10
		get_tree().current_scene.add_child(_pause_layer)
		_pause_layer.add_child(scene_dict.get(Enums.Scenes.PAUSE).instantiate())
		
func unpause_game():
	get_tree().paused = false
	_pause_layer.queue_free()
	
func update_furthest_level_reached(world: int, level: int):
	pass
	
func save_collectible(id: String):
	if  !_save_data["collectibles_acquired"].has(id):
		_save_data["collectibles_acquired"].append(id)
		_save_save_data()
	
func _load_scene(scene_to_load: Enums.Scenes):
	get_tree().call_deferred("change_scene_to_packed", scene_dict.get(scene_to_load))

func _fadeout(next_scene: Enums.Scenes):
	var fadeout_rect = _build_fadeout_rect(0)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 1.0, _transition_out_time)
	tween.tween_callback(_load_scene_fadein.bind(next_scene))

func _fadein():
	get_tree().disconnect("tree_changed", _fadein)
	var fadeout_rect = _build_fadeout_rect(1)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 0.0, _transition_in_time)
	tween.tween_callback(_remove_fadeout_rect.bind(fadeout_rect))

func _load_scene_fadein(scene_to_load: Enums.Scenes):
	get_tree().change_scene_to_packed(scene_dict.get(scene_to_load))
	get_tree().connect("tree_changed", _fadein)

func _remove_fadeout_rect(rect: ColorRect):
	get_tree().current_scene.remove_child(rect)

func _build_fadeout_rect(alpha: float) -> ColorRect:
	var fadeout_rect = ColorRect.new()
	fadeout_rect.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	fadeout_rect.color = Color(0, 0, 0, 1)
	fadeout_rect.modulate.a = alpha
	fadeout_rect.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	return fadeout_rect
	
func _input(event: InputEvent):
	if Input.is_action_just_pressed("Pause"):
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()
	if Input.is_action_just_pressed("DebugAction"):
		print("saving")
