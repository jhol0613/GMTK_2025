extends Agent

class_name PlayerCharacter


@export_subgroup("Sound")
@export var beat_delays: Dictionary[Enums.PlayerAction, float]

@export_subgroup("Sound emitters")
@export var move_left_emitter: FmodEventEmitter2D
@export var move_right_emitter: FmodEventEmitter2D
@export var move_up_emitter: FmodEventEmitter2D
@export var move_down_emitter: FmodEventEmitter2D
@export var jump_emitter: FmodEventEmitter2D

func _ready() -> void:
	action_executed.connect(_on_action_executed)


func _on_action_executed(action: Enums.PlayerAction) -> void:
	var emitter: FmodEventEmitter2D = null
	match action:
		Enums.PlayerAction.LEFT:
			emitter = move_left_emitter
		Enums.PlayerAction.RIGHT:
			emitter = move_right_emitter
		Enums.PlayerAction.UP:
			emitter = move_up_emitter
		Enums.PlayerAction.DOWN:
			emitter = move_down_emitter
		Enums.PlayerAction.JUMP:
			emitter = jump_emitter
	if emitter == null: # in case the action is not a movement action
		return
	emitter.play()
	await get_tree().create_timer(_get_delay_seconds(action)).timeout


func _get_delay_seconds(action: Enums.PlayerAction) -> float:
	return beat_delays.get(action, 0.0) * AudioManager.beat_time_seconds
