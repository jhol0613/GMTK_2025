extends Control

class_name ActionSlot

@export var active_texture: CompressedTexture2D
@export var inactive_texture: CompressedTexture2D

@onready var texture_rect = $TextureRect
@onready var background_sprite = $Sprite2D

var action: Enums.PlayerAction = Enums.PlayerAction.NONE

# If active is false, cannot drag and drop
var is_active := true

func set_active(active: bool):
	is_active = active
	if is_active:
		background_sprite.texture = active_texture
	else:
		background_sprite.texture = inactive_texture

func _can_drop_data(_position, data):
	return action == Enums.PlayerAction.NONE and data["type"] == "item" and data["quantity"] > 0


func _drop_data(_position, data):
	action = data["action"]
	texture_rect.texture = data["texture"]
	data["reference"].decrease_quantity()
	
func set_light_on(on: bool):
	$Backlight.visible = on
