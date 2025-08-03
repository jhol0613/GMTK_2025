extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	$bench.visible = false
	$bench/bench.visible = false
	pass # Replace with function body.


func _on_passenger_and_player_animation_finished() -> void:
	get_tree().change_scene_to_file("res://levels/test_level.tscn")
