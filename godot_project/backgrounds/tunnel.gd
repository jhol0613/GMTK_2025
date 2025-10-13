extends Node2D

class_name WorldTransitionTunnel

@export var scroll_speed := 500.0

##Returns amount of time until whole screen covered by tunnel
func get_time_until_screen_covered():
	return ProjectSettings.get_setting("display/window/size/viewport_width") \
		/ scroll_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= delta * scroll_speed
	pass
