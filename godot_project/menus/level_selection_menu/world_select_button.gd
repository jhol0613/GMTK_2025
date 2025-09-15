extends TextureButton

class_name WorldSelectButton

@onready var record_animation: AnimationPlayer = $RecordAnimation

@export var destination_scene: Enums.Scenes

var original_size := scale
var grow_size := Vector2(1.1, 1.1)

func lvl_btn_on_mouse_entered() -> void:
	record_animation.play("Move")
	grow_btn(grow_size, .1)

func lvl_btn_on_mouse_exited() -> void:
	grow_btn(original_size, .1)

func grow_btn(end_size: Vector2, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, 'scale', end_size, duration)

func lvl_btn_on_pressed() -> void:
	GameManager.load_scene(destination_scene, Enums.TransitionStyle.NONE)
