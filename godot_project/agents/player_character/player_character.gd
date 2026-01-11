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
var success_animation_delay := 0.3

@onready var _jumping = false
@onready var _ducking = false

signal failure

func _ready() -> void:
	super._ready()
	reset()
	action_executed.connect(_on_action_executed)
	play_animation_with_follow_on("enter", "idle_right")

func _on_action_executed(action: Enums.PlayerAction) -> void:
	#print(Enums.PlayerAction.find_key(action))
	if action == Enums.PlayerAction.JUMP:
		jump_collision_timer.start()
		_jumping = true
	elif action == Enums.PlayerAction.DUCK:
		duck_collision_timer.start()
		_ducking = true

func notify_success():
	await get_tree().create_timer(success_animation_delay).timeout
	play_animation_with_follow_on("success")
	success_emitter.play()

func notify_failure():
	failure_emitter.play()
	interrupt_queued_action()
	play_animation_with_follow_on("failure")
	
func disable_collisions() -> void:
	collision_area.process_mode = Node.PROCESS_MODE_DISABLED
	
func enable_collisions() -> void:
	collision_area.process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_laser_hit(area: Area2D):
	pass
	#var test = Enums.CollisionLayer.ENEMIES
	#if area.get_collision_layer_value(Enums.CollisionLayer.ENEMIES):
		#if (area.get_collision_layer_value(Enums.CollisionLayer.JUMPABLE) and _jumping):
			#return
		#if (area.get_collision_layer_value(Enums.CollisionLayer.DUCKABLE) and _ducking):
			#return
		#notify_failure()
		#failure.emit()

func _on_collision(area: Area2D) -> void:
	if area.get_collision_layer_value(Enums.CollisionLayer.ENEMIES):
		if (area.get_collision_layer_value(Enums.CollisionLayer.JUMPABLE) and _jumping):
			return
		if (area.get_collision_layer_value(Enums.CollisionLayer.DUCKABLE) and _ducking):
			return
		notify_failure()
		failure.emit()
		
func reset():
	super.reset()
	enable_collisions()

func on_jump_collision_disabled_expire() -> void:
	_jumping = false
	laser_blocker_collision_shape.disabled = false
	#collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, true)
	
func on_duck_collision_disabled_expire() -> void:
	laser_blocker_collision_shape.disabled = false
	_ducking = false
