extends Control

class_name ActionItem

@onready var texture_rect = $TextureRect
@onready var border = $Border

@export var preview_scene : PackedScene
@export var icon_dictionary: Dictionary[Enums.PlayerAction, CompressedTexture2D]

var action: Enums.PlayerAction
var quantity: int
var selected := false

signal action_item_clicked(clicked_action_item: ActionItem)

func _ready() -> void:
	border.modulate.a = 0
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
		"reference": self,
		"texture": texture_rect.texture
	}


func _on_texture_rect_mouse_entered() -> void:
	if not selected:
		texture_rect.position.y += -1

func _on_texture_rect_mouse_exited() -> void:
	if not selected:
		texture_rect.position.y += 1


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Use modulate alpha instead of visibility so changing visibility doesn't affect layout
			if not selected:
				border.modulate.a = 1
				texture_rect.position.y += 1
				selected = true
				action_item_clicked.emit(self)
		
func deselect():
	border.modulate.a = 0
	selected = false
