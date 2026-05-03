@tool

extends Agent

class_name TeleporterTarget

@export var _active = false

@export var _lights : AnimatedSprite2DSignals
@export var _glow : PointLight2D
@export var respawn_particles : Array[GPUParticles2D]

##Queues up a target to set it to active once this node has been initialized
var _queue_active = false
var _color

signal entity_should_reappear

func set_active(new_active_status):
	if not _lights:
		_queue_active = new_active_status
		return
	_active = new_active_status
	if _active:
		set_color(_color, 1.0)
		_lights.play_with_signals("update_destination")
		_glow.visible = true
		await _lights.animation_finished
		_lights.play_with_signals("active")
	else:
		_lights.play_with_signals("inactive")
		_glow.visible = false

func _ready() -> void:
	super._ready()
	if _queue_active:
		set_active(true)

func play_respawn_particles():
	for particle_system in respawn_particles:
		particle_system.emitting = true

func play_player_appear_animation(speed = 1.0):
	_lights.play_with_signals("respawn_player", speed)
	await _lights.animation_signal
	entity_should_reappear.emit()

func play_entity_appear_animation(speed = 1.0):
	_lights.play_with_signals("respawn_object", speed)
	await _lights.animation_signal
	entity_should_reappear.emit()

func set_color(color: Color, modulate_multiplier: float):
	color.v *= modulate_multiplier
	_color = color
	if not _active:
		color.s = color.s * .7
	_lights.modulate = color
	_glow.color = color

func reset():
	pass
