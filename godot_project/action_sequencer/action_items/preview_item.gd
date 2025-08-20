extends Control

@onready var texture_rect := $TextureRect

func set_icon(icon: CompressedTexture2D):
	print("setting icon")
	texture_rect.texture = icon
