extends Control

class_name ActionSlot

var has_action := false
var action: Enums.PlayerAction

@export var preview_scene: PackedScene


func _can_drop_data(_position, data):
	return not has_action and data["type"] == "item" and data["quantity"] > 0


func _drop_data(_position, data):
	action = data["action"]
	data["reference"].decrease_quantity()
	has_action = true
