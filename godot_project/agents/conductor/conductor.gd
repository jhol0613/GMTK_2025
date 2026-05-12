extends Movable


class_name Conductor


@onready var entered_emitter = $Sound/EnteredSound
@onready var grunt_emitter = $Sound/Grunt
@onready var emotes = $Shadow/AnimatedSprite2D/Emotes
@onready var collision = $Shadow/Area2D

var _first_action = true

var facing_direction = Enums.Direction.RIGHT
var state = Enums.ConductorState.UNAWARE

var stunned = false

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
		Enums.PlayerAction.LEFT:
			sprite.flip_h = true
			facing_direction = Enums.Direction.LEFT
		Enums.PlayerAction.RIGHT:
			sprite.flip_h = false
			facing_direction = Enums.Direction.RIGHT
		_:
			pass

func play_current_emotion():
	match state:
		Enums.ConductorState.ANGRY:
			emotes.animation = "angry"
		Enums.ConductorState.FOUND:
			emotes.animation = "aware"
		Enums.ConductorState.UNREACHABLE_START:
			emotes.animation = "unreachable"
		# TODO: add emotion "snooze" here
		_:
			return
	emotes.play()
	await emotes.animation_finished
	emotes.animation = "default"
	emotes.play()

func set_enemy_collision(value: bool) -> void:
	collision.set_collision_layer_value(Enums.CollisionLayer.ENEMIES, value)

func _on_laser_hit(area: Area2D) -> void:
	if area.get_collision_layer_value(Enums.CollisionLayer.LASERS):
		grunt_emitter.play()
		# TODO: conductor: add stun animation
		stunned = true
