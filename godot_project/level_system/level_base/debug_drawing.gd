extends Node2D

class_name DebugDrawing

@export var rectangle_size := Vector2(20, 15)
@export var rectangle_color := Color.RED
## Offset from centerpoint
@export var offset := Vector2(0, -7)

@onready var rectangle_centers: Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


	
func _draw() -> void:
	for centerpoint in rectangle_centers:
		var rect = Rect2(centerpoint - .5 * rectangle_size + offset, rectangle_size)
		draw_rect(rect, rectangle_color, true)
