@tool
extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material.set_shader_parameter("y_zoom", get_viewport_transform().get_scale().y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#material.set_shader_parameter("y_zoom", get_viewport_transform().get_scale().y)
	#print(get_viewport_transform().get_scale().y)
