extends Node2D

class_name DebugDrawing

@export var rectangle_size := Vector2(20, 15)
@export var rectangle_color := Color.RED
## Offset from centerpoint
@export var offset := Vector2(0, -7)
@export var font : Font

@onready var rectangle_centers: Array[Vector2] = []

## Container of pairs of text and position
@onready var text_instances: Array[String]
@onready var text_positions: Array[Vector2]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func clear_data():
	rectangle_centers.clear()
	text_instances.clear()
	text_positions.clear()

func _draw() -> void:
	for centerpoint in rectangle_centers:
		var rect = Rect2(centerpoint - .5 * rectangle_size + offset, rectangle_size)
		draw_rect(rect, rectangle_color, true)
	for i in range(text_instances.size()):
		draw_string(font, text_positions[i], text_instances[i], 0, -1, 5)
