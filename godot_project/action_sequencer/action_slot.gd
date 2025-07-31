extends Control

class_name ActionSlot

var action: Enums.PlayerAction = Enums.PlayerAction.NONE


func _can_drop_data(_position, data):
	return action == Enums.PlayerAction.NONE and data["type"] == "item" and data["quantity"] > 0


func _drop_data(_position, data):
	action = data["action"]
	data["reference"].decrease_quantity()
