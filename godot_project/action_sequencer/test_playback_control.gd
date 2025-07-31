extends Node


signal playback_play

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Play"):
		playback_play.emit()
