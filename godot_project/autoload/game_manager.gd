extends Node2D

@export_subgroup("Scenes")
@export var scene_dict: Dictionary[Enums.Scenes, PackedScene]

@export_subgroup("Animation")
@export var default_fade_out_time := 1.0
@export var default_fade_in_time := 1.0

@onready var _transition_out_time = default_fade_out_time
@onready var _transition_in_time = default_fade_in_time

func _ready():
	pass
	
func load_scene(scene: Enums.Scenes, transition_in_time = default_fade_in_time, 
	transition_out_time = default_fade_out_time, transition_style = "fade_out_in"):
		
	_transition_out_time = transition_out_time
	_transition_in_time = transition_in_time
	
	match transition_style:
		"fade_out_in":
			_fadeout(scene)
	
func _fadeout(next_scene: Enums.Scenes):
	var fadeout_rect = _build_fadeout_rect(0)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 1.0, _transition_out_time)
	tween.tween_callback(_load_scene.bind(next_scene))
	
func _fadein():
	get_tree().disconnect("tree_changed", _fadein)
	var fadeout_rect = _build_fadeout_rect(1)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 0.0, _transition_in_time)
	tween.tween_callback(_remove_fadeout_rect.bind(fadeout_rect))
	
func _load_scene(scene_to_load: Enums.Scenes):
	print("attempting load")
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
