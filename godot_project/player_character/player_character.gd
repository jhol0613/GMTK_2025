extends Agent

class_name PlayerCharacter


@export_subgroup("Sound emitters")
@export var move_left_emitter: FmodEventEmitter2D
@export var move_right_emitter: FmodEventEmitter2D
@export var move_up_emitter: FmodEventEmitter2D
@export var move_down_emitter: FmodEventEmitter2D
@export var jump_emitter: FmodEventEmitter2D
@export var bonk_emitter: FmodEventEmitter2D
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
			jump_collision_timer.start()
			collision.collision_layer = 0
			collision.collision_mask = 0
			emitter = jump_emitter
		Enums.PlayerAction.LEFT_BONK, Enums.PlayerAction.RIGHT_BONK, Enums.PlayerAction.UP_BONK, Enums.PlayerAction.DOWN_BONK:
			emitter = bonk_emitter
	if emitter == null: # in case the action is not a movement action
		return
	emitter.play()

func notify_success():
	sprite.play("success")
	success_emitter.play()

func notify_failure():
	failure_emitter.play()
	interrupt_queued_animation()
	sprite.play("failure")

func disable_collisions() -> void:
	collision.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE


func _on_collision(area: Area2D) -> void:
	if area.collision_layer & Enums.CollisionLayer.ENEMIES:
		notify_failure()
		failure.emit()

func on_jump_collision_disabled_expire() -> void:
	collision.collision_layer = original_collision_layer
	collision.collision_mask = original_collision_mask
