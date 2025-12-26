@tool

extends Node2D

class_name WorldTransitionTunnel

@export var scroll_speed := 900.0

##Creates a parallax effect by changing the speed at which certain sprites scroll. Numbers are given as offset
##relative to the base scroll_speed. Sprites that aren't included will scroll at the base speed
@export var relative_scrolls : Dictionary[Sprite2D, float]
			
##Returns amount of time until whole screen covered by tunnel
func get_time_until_screen_covered():
	return ProjectSettings.get_setting("display/window/size/viewport_width") \
		/ scroll_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= delta * scroll_speed
	
	for sprite in relative_scrolls.keys():
		sprite.position.x -= delta * relative_scrolls[sprite]
