extends Node2D

class_name Agent

signal tick(beat: int)

# agent's position inside of the grid
var grid_position := Vector2i(0, 0)
# grid's tile size for calculating the local position
var tile_size: Vector2i
# agent's initial position in the grid
@export var grid_origin := Vector2i.ZERO
# grid origin in local coordinate space to calculate local grid cell position
var local_origin := Vector2.ZERO
# grid total size
var grid_size := Vector2i.ZERO

func _ready() -> void:
	reset()

func reset() -> void:
	grid_position = grid_origin
	position = _grid_to_local(grid_position)

func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)
