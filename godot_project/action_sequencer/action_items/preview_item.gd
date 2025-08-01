extends Control

@onready var texture_rect := $TextureRect

func set_icon(icon: CompressedTexture2D):
	texture_rect.texture = icon
