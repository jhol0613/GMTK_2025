extends Control

class_name ActionItem


var action: Enums.PlayerAction
var quantity: int

@export var preview_scene: PackedScene

func decrease_quantity():
	quantity -= 1
	# TODO: update quantity UI here


func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(preview_scene.instantiate())
	return {
		"type": "item",
		"action": action,
		"quantity": quantity,
		"reference": self
	}
