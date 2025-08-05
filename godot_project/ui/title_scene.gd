extends Control


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
