extends Agent


class_name Conductor


@onready var entered_emitter = $Sound/EnteredSound

var _first_action = true

func _ready():
	super._ready()
	action_executed.connect(_on_action_executed)

func _on_action_executed(action: Enums.PlayerAction) -> void:
	if _first_action:
		_first_action = false
		entered_emitter.play()
		return
	match action:
		Enums.PlayerAction.RIGHT, Enums.PlayerAction.UP, Enums.PlayerAction.DOWN:
			sprite.flip_h = false
		Enums.PlayerAction.LEFT:
			sprite.flip_h = true
