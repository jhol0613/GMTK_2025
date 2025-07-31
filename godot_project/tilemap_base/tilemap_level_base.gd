extends Node2D

class_name TilemapLevel

@export var bounds : Vector2i

@onready var _floor_layer : TileMapLayer = $Floor
@onready var _obstacle_layer : TileMapLayer = $Obstacles
@onready var _wall_layer : TileMapLayer = $Wall

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func get_traversible_neighbors(grid_position: Vector2i) -> Array[Vector2i]:
	var neighbors = _obstacle_layer.get_surrounding_cells(grid_position)
	var neighbors_to_return : Array[Vector2i]
	
	for neighbor in neighbors:
		var cell_exists = (_floor_layer.get_cell_source_id(neighbor) != -1 and
			_floor_layer.get_cell_atlas_coords(neighbor) != Vector2i(-1,-1))
		
		var tile_data = _obstacle_layer.get_cell_tile_data(neighbor)
		var cell_traversible = true # Traversible if the cell is unoccupied
		
		if tile_data:
			cell_traversible = tile_data.get_custom_data("Traversible")
		
		if cell_exists and cell_traversible:
			neighbors_to_return.append(neighbor)
		
	return neighbors_to_return
	
func get_vertical_tile_spacing():
	return _floor_layer.tile_set.tile_size.y
	
func get_horizontal_tile_spacing():
	return _floor_layer.tile_set.tile_size.x
	
## Take global coordinates and convert to map coordinates
func global_to_map(coordinates : Vector2):
	return _floor_layer.local_to_map(_floor_layer.to_local(coordinates))
	
	
