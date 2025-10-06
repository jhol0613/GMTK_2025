extends Button

class_name LevelSelectButton

@export var destination_world := -1
@export var destination_level := -1

var original_size := scale
var grow_size := Vector2(1.1, 1.1)

func _init(world: int, level: int):
	destination_world = world
	destination_level = level

func _ready() -> void:
	text = GameManager.level_catalog.get_display_name(destination_world, destination_level)
	connect("mouse_entered", lvl_btn_on_mouse_entered)
	connect("mouse_exited", lvl_btn_on_mouse_exited)
	connect("pressed", lvl_btn_on_pressed)

func lvl_btn_on_mouse_entered() -> void:
	grow_btn(grow_size, .1)

func lvl_btn_on_mouse_exited() -> void:
	grow_btn(original_size, .1)

func grow_btn(end_size: Vector2, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, 'scale', end_size, duration)

func lvl_btn_on_pressed() -> void:
	var level_scene = GameManager.level_catalog.get_level(destination_world, destination_level)
	get_tree().call_deferred("change_scene_to_packed", level_scene)
