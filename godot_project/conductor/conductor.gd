extends Agent


class_name Conductor

signal player_caught

@onready var jump_emitter = $Sound/JumpSound
@onready var entered_emitter = $Sound/EnteredSound
@onready var voice_emitter = $Sound/Voice

var _first_action = true

func _ready():
	super._ready()
	action_executed.connect(_on_action_executed)

func _on_action_executed(action: Enums.PlayerAction) -> void:
	if _first_action:
		_first_action = false
		entered_emitter.play()
		return
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

func _on_player_entered(_area: Area2D) -> void:
	player_caught.emit()
