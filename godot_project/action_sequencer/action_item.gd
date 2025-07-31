extends Control

class_name ActionItem


var action: Enums.PlayerAction
var quantity: int

@export var preview_scene: PackedScene

func decrease_quantity():
	quantity -= 1


func _get_drag_data(at_position: Vector2) -> Variant:
	set_drag_preview(preview_scene.instantiate())
	return {"action": action, "quantity": quantity, "reference": self}
