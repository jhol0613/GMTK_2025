extends Control

class_name ActionSlot

@onready var texture_rect = $TextureRect

var action: Enums.PlayerAction = Enums.PlayerAction.NONE


func _can_drop_data(_position, data):
	return action == Enums.PlayerAction.NONE and data["type"] == "item" and data["quantity"] > 0


func _drop_data(_position, data):
	action = data["action"]
	texture_rect.texture = data["texture"]
	data["reference"].decrease_quantity()
	
func set_light_on(on: bool):
	$Backlight.visible = on
