extends Agent


class_name Conductor

signal player_caught

@onready var jump_emitter = $Sound/JumpSound
@onready var entered_emitter = $Sound/EnteredSound
@onready var voice_emitter = $Sound/Voice

func _ready():
	super._ready()
	action_executed.connect(_on_action_executed)

func _on_action_executed(action: Enums.PlayerAction) -> void:
	var emitter: FmodEventEmitter2D = null
	match action:
		Enums.PlayerAction.RIGHT, Enums.PlayerAction.UP, Enums.PlayerAction.DOWN:
			sprite.flip_h = false
			emitter = jump_emitter
		Enums.PlayerAction.LEFT:
			sprite.flip_h = true
			emitter = jump_emitter
	
	if emitter == null: # in case the action is not a movement action
		return
	emitter.play()

func _on_player_entered(area: Area2D) -> void:
	player_caught.emit()
