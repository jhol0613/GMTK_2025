extends Movable

class_name PlayerCharacter


@export_subgroup("Sound emitters")
@export var success_emitter: FmodEventEmitter2D
@export var failure_emitter: FmodEventEmitter2D


@export_subgroup("Nodes")
## Collision object to disable after the event happens
#@export var collision: CollisionObject2D
@export var jump_collision_timer: Timer

@onready var _jumping = false

signal failure

func _ready() -> void:
	super._ready()
	action_executed.connect(_on_action_executed)
	play_animation("enter", "idle_right")

func _on_action_executed(action: Enums.PlayerAction) -> void:
	match action:
		Enums.PlayerAction.JUMP:
			jump_collision_timer.start()
			_jumping = true
			collision_area.set_collision_layer_value(6, false)

func notify_success():
	play_animation("success")
	success_emitter.play()

func notify_failure():
	failure_emitter.play()
	interrupt_queued_animation()
	play_animation("failure")

func disable_collisions() -> void:
	collision_area.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE # I don't think this line is doing anything relevant any more, just nervous to take it out


func _on_collision(area: Area2D) -> void:
	if area.get_collision_layer_value(Enums.CollisionLayer.ENEMIES):
		if (area.get_collision_layer_value(Enums.CollisionLayer.JUMPABLE) and _jumping):
			return
		notify_failure()
		failure.emit()

func on_jump_collision_disabled_expire() -> void:
	_jumping = false
	collision_area.set_collision_layer_value(6, true)
