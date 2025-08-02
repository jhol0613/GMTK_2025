extends Agent

class_name PlayerCharacter


@export_subgroup("Sound emitters")
@export var move_left_emitter: FmodEventEmitter2D
@export var move_right_emitter: FmodEventEmitter2D
@export var move_up_emitter: FmodEventEmitter2D
@export var move_down_emitter: FmodEventEmitter2D
@export var jump_emitter: FmodEventEmitter2D

@export_subgroup("Nodes")
## Collision object to disable after the event happens
@export var collision: CollisionObject2D

func _ready() -> void:
	super._ready()
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


func disable_collisions() -> void:
	collision.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE
