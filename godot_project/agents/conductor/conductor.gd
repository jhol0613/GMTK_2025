extends Movable


class_name Conductor


@onready var entered_emitter = $Sound/EnteredSound
@onready var emotes = $Shadow/AnimatedSprite2D/Emotes

var _first_action = true

var facing_direction = Enums.Direction.RIGHT
var state = Enums.ConductorState.UNAWARE

func _ready():
	super._ready()
	reset()
	action_executed.connect(_on_action_executed)

func _on_action_executed(action: Enums.PlayerAction) -> void:
	if _first_action:
		_first_action = false
		entered_emitter.play()
		return
	match action:
		Enums.PlayerAction.RIGHT, Enums.PlayerAction.UP, Enums.PlayerAction.DOWN:
			sprite.flip_h = false
			facing_direction = Enums.Direction.RIGHT
		Enums.PlayerAction.LEFT:
			sprite.flip_h = true
			facing_direction = Enums.Direction.LEFT

func play_current_emotion():
	match state:
		Enums.ConductorState.ANGRY:
			emotes.animation = "angry"
		Enums.ConductorState.FOUND:
			emotes.animation = "aware"
		Enums.ConductorState.UNREACHABLE_START:
			emotes.animation = "unreachable"
		_:
			return
	emotes.play()
	await emotes.animation_finished
	emotes.animation = "default"
	emotes.play()
