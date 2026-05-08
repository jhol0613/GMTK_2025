extends Control

##There are this many steps between left and right side of the screen. e.g. If steps is 5, conductor will
##start moving right when count is less than 5
@export var steps := 5
##Position conductor animation will move to
@export var right_pos := 72.0
@export var animation_time := .5

@onready var _spawn_text = $ConductorSpawnCountdown
@onready var _spawn_animation = $ConductorSpawnAnim
@onready var left_pos : float = _spawn_animation.position.x

var tween = create_tween()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.

func set_initial_spawn_countdown(new_value):
	tween.stop()
	if new_value == 0:
		_hide_spawn_countdown(true)
		return
	_hide_spawn_countdown(false)
	if new_value <= steps:
		_spawn_animation.position.x = lerp(left_pos, right_pos, 1 - float(new_value) / steps)
	else:
		_spawn_animation.position.x = left_pos
	_spawn_text.text = str(new_value)

func update_spawn_countdown(new_value):
	if new_value == 0:
		_spawn_animation.play("exit")
		_spawn_text.text = str(new_value)
		await _spawn_animation.animation_finished
		_hide_spawn_countdown(true)
	else:
		_hide_spawn_countdown(false)
		_spawn_animation.play("jump")
		_spawn_text.text = str(new_value)
	if new_value <= steps:
		var tween = create_tween()
		tween.tween_property(_spawn_animation, "position:x", 
			lerp(left_pos, right_pos, 1 - float(new_value) / steps), animation_time)
	await _spawn_animation.animation_finished
	_spawn_animation.play("idle")

func _hide_spawn_countdown(hidden):
	_spawn_text.visible = not hidden
	_spawn_animation.visible = not hidden
	_spawn_animation.play("idle")
