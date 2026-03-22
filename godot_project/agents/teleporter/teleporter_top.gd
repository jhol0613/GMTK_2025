@tool

extends Node2D

##Visuals for top part of a teleporter. Has no functionality except animation
class_name TeleporterTop

@export var sprite : AnimatedSprite2DSignals

#func play_teleport_animation():
	#sprite.play_with_signals("teleport")
#
###Animation should start this long before the actual teleportation
#func get_animation_offset():
	#return sprite.default_animation_offset
