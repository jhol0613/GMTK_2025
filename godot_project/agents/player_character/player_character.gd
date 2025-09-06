extends Movable

class_name PlayerCharacter


@export_subgroup("Sound emitters")
@export var success_emitter: FmodEventEmitter2D
@export var failure_emitter: FmodEventEmitter2D


@export_subgroup("Nodes")
## Collision object to disable after the event happens
@export var collision: CollisionObject2D
@export var jump_collision_timer: Timer

@onready var original_collision_mask = collision.collision_mask
@onready var original_collision_layer = collision.collision_layer

signal failure

func _ready() -> void:
	super._ready()
	action_executed.connect(_on_action_executed)
	play_animation("enter", "idle_right")


func _on_action_executed(action: Enums.PlayerAction) -> void:
	match action:
		Enums.PlayerAction.JUMP:
			jump_collision_timer.start()
			collision.collision_layer = 0
			collision.collision_mask = 0

func notify_success():
	play_animation("success")
	success_emitter.play()

func notify_failure():
	failure_emitter.play()
	interrupt_queued_animation()
	play_animation("failure")

func disable_collisions() -> void:
	collision.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE


func _on_collision(area: Area2D) -> void:
	if area.collision_layer & Enums.CollisionLayer.ENEMIES:
		notify_failure()
		failure.emit()

func on_jump_collision_disabled_expire() -> void:
	collision.collision_layer = original_collision_layer
	collision.collision_mask = original_collision_mask
