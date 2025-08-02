extends Node2D

class_name TilemapLevel

@export var next_level_path: String
@export var associated_sequencer_level: String
@export var bounds : Vector2i

@onready var _floor_layer : TileMapLayer = $Floor
@onready var _obstacle_layer : TileMapLayer = $Obstacles
@onready var _wall_layer : TileMapLayer = $BackWall

signal target_reached

var path_grid: AStarGrid2D

func _ready() -> void:
	_initialize_path_finding()


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

func get_tile_size() -> Vector2i:
	return _floor_layer.tile_set.tile_size


## Take global coordinates and convert to map coordinates
func global_to_map(coordinates : Vector2):
	return _floor_layer.local_to_map(_floor_layer.to_local(coordinates))

func map_to_local(grid_position: Vector2i):
	return _floor_layer.map_to_local(grid_position)

# cycles through each tile in the tile layer, adding it to the path finding node
func _initialize_path_finding():
	path_grid = AStarGrid2D.new()
	path_grid.region = _floor_layer.get_used_rect() \
		.merge(_obstacle_layer.get_used_rect())
	path_grid.cell_size = _floor_layer.tile_set.tile_size
	path_grid.offset = path_grid.cell_size * 0.5
	path_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	path_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	path_grid.update()
	
	for tile in _obstacle_layer.get_used_cells():
		path_grid.set_point_solid(tile)
	path_grid.update()
	
	# debug
	print("Tile map data: ", path_grid)


func _on_target_area_entered(area: Area2D) -> void:
	target_reached.emit()
