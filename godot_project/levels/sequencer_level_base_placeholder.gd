extends Node2D

signal player_action_received(action: Enums.PlayerAction)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Up"):
		player_action_received.emit(Enums.PlayerAction.UP)
	if event.is_action_pressed("Down"):
		player_action_received.emit(Enums.PlayerAction.DOWN)
	if event.is_action_pressed("Left"):
		player_action_received.emit(Enums.PlayerAction.LEFT)
	if event.is_action_pressed("Right"):
		player_action_received.emit(Enums.PlayerAction.RIGHT)
