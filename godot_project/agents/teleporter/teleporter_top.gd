@tool

extends Node2D

##Visuals for top part of a teleporter. Has no functionality except animation
class_name TeleporterTop

signal powered_up

@export var lights_sprite : AnimatedSprite2DSignals
@export var sprite : AnimatedSprite2DSignals
@export var lights : Array[Light2D]

func _ready():
	lights_sprite.animation_signal.connect(_on_animation_signal)
	lights_sprite.animation_finished.connect(_on_animation_finished)

func power_up():
	lights_sprite.play_with_signals("power_up")

func _on_animation_signal(signal_id: String):
	match signal_id:
		"light1":
			lights[0].visible = true
		"light2":
			lights[1].visible = true
		"light3":
			lights[2].visible = true
			powered_up.emit()

func _on_animation_finished():
	for light in lights:
		light.visible = false
