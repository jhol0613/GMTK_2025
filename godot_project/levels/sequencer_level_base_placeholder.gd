extends Node2D

signal player_action_received(action: Enums.PlayerAction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Up"):
		player_action_received.emit(Enums.PlayerAction.UP)
	if event.is_action_pressed("Down"):
		player_action_received.emit(Enums.PlayerAction.DOWN)
	if event.is_action_pressed("Left"):
		player_action_received.emit(Enums.PlayerAction.LEFT)
	if event.is_action_pressed("Right"):
		player_action_received.emit(Enums.PlayerAction.RIGHT)
