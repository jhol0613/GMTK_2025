extends Node2D

@export_subgroup("Scenes")
@export var scene_dict: Dictionary[Enums.Scenes, PackedScene]
## Scenes must explicitly set pause enabled to true
@export var pause_enabled := false

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
	fadeout_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fadeout_rect


func _save_solution(index: int) -> void:
	if not OS.is_debug_build():
		return
	var level_manager = get_node("/root/LevelManager")
	if level_manager == null or level_manager is not LevelManager:
		push_error("[GameManager] Couldn't find LevelManager!")
		return
	var sequencer = get_node("/root/LevelManager/SequencerLayer/ActionSequencer")
	if sequencer == null or sequencer is not ActionSequencer:
		push_error("[GameManager] Couldn't find ActionSequencer!")
		return
	SaveManager.save_solution(sequencer.get_current_sequence(), level_manager.get_current_level_uid(), index)

func _load_solution(index: int) -> void:
	if not OS.is_debug_build():
		return
	var level_manager = get_node("/root/LevelManager")
	if level_manager == null or level_manager is not LevelManager:
		push_error("[GameManager] Couldn't find LevelManager!")
		return
	var sequencer = get_node("/root/LevelManager/SequencerLayer/ActionSequencer")
	if sequencer == null or sequencer is not ActionSequencer:
		push_error("[GameManager] Couldn't find ActionSequencer!")
		return
	var solution = SaveManager.load_solution(level_manager.get_current_level_uid(), index)
	sequencer.set_current_sequence(solution)

func _input(_event: InputEvent):
	if Input.is_action_just_pressed("Pause"):
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()
	if Input.is_action_just_pressed("DebugAction"):
		print("saving")

	if Input.is_action_just_pressed("Save1"):
		_save_solution(1)
		return
	if Input.is_action_just_pressed("Save2"):
		_save_solution(2)
		return
	if Input.is_action_just_pressed("Save3"):
		_save_solution(3)
		return
	if Input.is_action_just_pressed("Save4"):
		_save_solution(4)
		return
	if Input.is_action_just_pressed("Save5"):
		_save_solution(5)
		return
	if Input.is_action_just_pressed("Save6"):
		_save_solution(6)
		return
	if Input.is_action_just_pressed("Save7"):
		_save_solution(7)
		return
	if Input.is_action_just_pressed("Save8"):
		_save_solution(8)
		return
	if Input.is_action_just_pressed("Save9"):
		_save_solution(9)
		return
	if Input.is_action_just_pressed("Save10"):
		_save_solution(10)
		return

	if Input.is_action_just_pressed("Load1"):
		_load_solution(1)
	if Input.is_action_just_pressed("Load2"):
		_load_solution(2)
	if Input.is_action_just_pressed("Load3"):
		_load_solution(3)
	if Input.is_action_just_pressed("Load4"):
		_load_solution(4)
	if Input.is_action_just_pressed("Load5"):
		_load_solution(5)
	if Input.is_action_just_pressed("Load6"):
		_load_solution(6)
	if Input.is_action_just_pressed("Load7"):
		_load_solution(7)
	if Input.is_action_just_pressed("Load8"):
		_load_solution(8)
	if Input.is_action_just_pressed("Load9"):
		_load_solution(9)
	if Input.is_action_just_pressed("Load10"):
		_load_solution(10)
