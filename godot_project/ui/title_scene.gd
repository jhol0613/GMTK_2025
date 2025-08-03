extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	$ClickStartEmitter.play()
	get_tree().change_scene_to_file("res://levels/test_level.tscn")
	pass # Replace with function body.


func _on_play_mouse_entered() -> void:
	$HoverEmitter.play()


func _on_options_mouse_entered() -> void:
	$HoverEmitter.play()
	pass # Replace with function body.
