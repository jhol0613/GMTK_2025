extends Control

class_name ActionItem

@onready var texture_rect = $TextureRect

@export var preview_scene : PackedScene
@export var icon_dictionary: Dictionary[Enums.PlayerAction, CompressedTexture2D]

var action: Enums.PlayerAction
var quantity: int


func _ready() -> void:
	pass
	
func set_action(new_action: Enums.PlayerAction):
	action = new_action
	texture_rect.texture = icon_dictionary.get(action)

func decrease_quantity():
	quantity -= 1
	# TODO: update quantity UI here


func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag_preview = preview_scene.instantiate()
	set_drag_preview(drag_preview)
	drag_preview.set_icon(texture_rect.texture)
	return {
		"type": "item",
		"action": action,
		"quantity": quantity,
		"reference": self
	}
