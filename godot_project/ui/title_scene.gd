extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	$ClickStartEmitter.play()
	var tween = create_tween()
	tween.tween_property($TransitionColor, "modulate:a", 1.0, 0.5)
	tween.tween_callback(load_first_level)

func load_first_level():
	get_tree().change_scene_to_file("res://ui/narrative.tscn")


func _on_play_mouse_entered() -> void:
	$HoverEmitter.play()


func _on_options_mouse_entered() -> void:
	$HoverEmitter.play()
	pass # Replace with function body.
