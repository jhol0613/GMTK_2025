extends Movable

class_name PlayerCharacter


@export_subgroup("Sound emitters")
@export var success_emitter: FmodEventEmitter2D
@export var failure_emitter: FmodEventEmitter2D


@export_subgroup("Nodes")
## Collision object to disable after the event happens
#@export var collision: CollisionObject2D
@export var jump_collision_timer: Timer
@export var duck_collision_timer: Timer
@export var laser_blocker: LaserBlocker
@export var laser_blocker_collision_shape: CollisionShape2D

@export_subgroup("Animation")
##Time to wait before playing success animation (to give sprite a chance to physically catch up to triggered location)
@export var success_animation_delay := 0.3

@export_subgroup("Dodging")
##Jumping will dodge lasers of up to this height
@export var jump_clearance := 28
##Laser blocker will shrink to this height during jump
@export var jump_player_height := 42
##Ducking will dodge lasers as low as this height
@export var duck_height := 28

@onready var _jumping = false
@onready var _ducking = false
@onready var _laser_blocker_collision_rectangle: RectangleShape2D = laser_blocker_collision_shape.shape
@onready var _original_laser_blocker_height = _laser_blocker_collision_rectangle.size.y
@onready var _original_laser_blocker_position = laser_blocker.position

signal failure

func _ready() -> void:
	super._ready()
	reset()
	action_executed.connect(_on_action_executed)
	play_animation_with_follow_on("enter", "idle_right")

func _on_action_executed(action: Enums.PlayerAction) -> void:
	print(Enums.PlayerAction.find_key(action))
	if action == Enums.PlayerAction.JUMP:
		jump_collision_timer.start()
		#use y magnitude of jump for
		laser_blocker.altitude = jump_clearance
		laser_blocker.position.y -= jump_clearance
		_laser_blocker_collision_rectangle.size.y = jump_player_height
		_jumping = true
	elif action == Enums.PlayerAction.DUCK:
		# Move blocker down so the base of the blocker stays in the same place when it changes sizes
		laser_blocker.position.y += 0.5 * (_laser_blocker_collision_rectangle.size.y - duck_height)
		_laser_blocker_collision_rectangle.size.y = duck_height
		duck_collision_timer.start()
		_ducking = true

func notify_success():
	await get_tree().create_timer(success_animation_delay).timeout
	play_animation_with_follow_on("success")
	success_emitter.play()

func notify_failure(cause: Enums.FailureCause):
	failure_emitter.play()
	interrupt_queued_action()
	var animation_to_play = "failure"
	match cause:
		Enums.FailureCause.LASER:
			animation_to_play = "failure_laser"
		Enums.FailureCause.SQUISHED:
			animation_to_play = "failure_squish"
	print("Failure animation: %s" % animation_to_play)
	play_animation_with_follow_on(animation_to_play, "cancel_follow_on")

func disable_collisions() -> void:
	collision_area.process_mode = Node.PROCESS_MODE_DISABLED

func enable_collisions() -> void:
	collision_area.process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_laser_hit(area: Area2D):
	if area.get_collision_layer_value(Enums.CollisionLayer.LASERS):
		notify_failure(Enums.FailureCause.LASER)
		failure.emit()

func _on_collision(area: Area2D) -> void:
	if area.get_collision_layer_value(Enums.CollisionLayer.LASERS):
		return #let laser blocker area deal with it
	elif area.get_collision_layer_value(Enums.CollisionLayer.ENEMIES):
		var cause = Enums.FailureCause.CAUGHT
		if (area.get_collision_layer_value(Enums.CollisionLayer.LASERS)):
			cause = Enums.FailureCause.LASER
		notify_failure(cause)
		failure.emit()

func reset():
	super.reset()
	enable_collisions()

func on_jump_collision_disabled_expire() -> void:
	_jumping = false
	laser_blocker.altitude = 0
	laser_blocker_collision_shape.disabled = false
	laser_blocker.position = _original_laser_blocker_position
	_laser_blocker_collision_rectangle.size.y = _original_laser_blocker_height
	#collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, true)

func on_duck_collision_disabled_expire() -> void:
	laser_blocker_collision_shape.disabled = false
	_ducking = false
	laser_blocker.position = _original_laser_blocker_position
	_laser_blocker_collision_rectangle.size.y = _original_laser_blocker_height
