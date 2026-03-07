@tool # to show teleporter's destination reticle in editor
extends Node2D

class_name RhythmRailLevel

@export_subgroup("LevelInfo")
@export var display_name:= "Unnamed Level"

@export_subgroup("Player", "player")
## Where on the tilemap the player should spawn
@export var player_spawn_position: Vector2i

@export_subgroup("Conductor", "conductor")
@export var conductor_spawn_beat := 2
## Where in the car grid the conductor should appear
@export var conductor_spawn_position := Vector2i(0, 2)
@export var conductor_enabled := true

@export_subgroup("Sequencer Data")
##How many slots should be available in the sequencer
@export_range(0, 8) var available_slots: int = 8
##The actions the player can select from on this level
@export var available_actions: Array[Enums.PlayerAction] = []
##The limit of each type of action available to the player
@export var action_quantities: Array[int] = []
@export var tutorial_mode := false

@onready var _floor_layer : TileMapLayer = $Floor
@onready var _obstacle_layer : TileMapLayer = $Obstacles
@onready var _debug_drawing_layer : DebugDrawing = $DebugDrawing
@onready var _target := $Target

##Any grid position in this array will be treated as if it contains an obstacle when checking traversibility
@onready var _obstacle_overrides: Array[Vector2i]

#TODO: These arrays could be refactored to use Godot's Groups system
## agents in the level to call update function to
var agents := []
## movable_obstacles in the level except the player and conductor
var movable_obstacles := []
## collectibles in the level
var collectibles := []
## pushers in the level
var pushers := []
## interactables in the level
var interactables := []
## obstacle spawners in the level
var obstacle_spawners := []
## lasers in the level
var lasers := []
## teleporters in the level
var teleporters := []
## terminals in the level
var terminals := []
## antennas in the level (treated like terminals, but aren't an agent so need their own array
var antennas := []

signal target_reached

var path_grid: AStarGrid2D
var target_position: Vector2i

func _enter_tree() -> void:
	# If scene is started and isn't the child of the level manager, load itself properly via the level manager.
	# this allows you to play a level with F6 if you have it open in the editor and it's in the level catalog
	if get_parent() == get_tree().root:
		var index = GameManager.level_catalog.get_index(self)
		GameManager.start_world = index.get("world")
		GameManager.start_level = index.get("level")
		GameManager.load_scene(Enums.Scenes.LEVEL_MANAGER, Enums.TransitionStyle.NONE)

func _ready() -> void:
	var children = find_children("*", "", true) # find children recursively
	for child in children:
		if child.is_in_group("agents"):
			agents.append(child)
		if child.is_in_group("collectibles"):
			collectibles.append(child)
		if child.is_in_group("movable_obstacles"):
			movable_obstacles.append(child)
		if child.is_in_group("pushers"):
			pushers.append(child)
		if child.is_in_group("interactables"):
			interactables.append(child)
		if child.is_in_group("obstacle_spawners"):
			obstacle_spawners.append(child)
		if child.is_in_group("lasers"):
			lasers.append(child)
		if child.is_in_group("teleporters"):
			teleporters.append(child)
		if child.is_in_group("terminals"):
			terminals.append(child)
		if child.is_in_group("antennas"):
			antennas.append(child)
	#agents = get_tree().get_nodes_in_group("agents")
	for agent: Agent in agents:
		# The position of the agent in level space
		var local_offset = to_local(agent.global_position) - agent.position
		agent.local_origin = map_to_local(Vector2i.ZERO) - local_offset
		agent.tile_size = get_tile_size()
		agent.grid_position = global_to_map(agent.global_position)
		agent.grid_origin = global_to_map(agent.global_position)
		agent.grid_size = get_grid_size()

	_initialize_path_finding()

	target_position = global_to_map(_target.global_position)

	if get_tree().debug_collisions_hint:
		_draw_obstacle_traversibility()

## Returns number of cells in given direction before hitting an obstacle
func get_cells_to_obstacle(grid_position: Vector2i, direction: Enums.Direction):
	var cells = 0
	var check_position = grid_position
	for i in range(100):
		check_position = check_position + Enums.direction_to_vector(direction)
		if !is_cell_navigable(check_position):
			return cells
		cells += 1

func get_cells_to_level_edge(grid_position: Vector2i, direction: Enums.Direction):
	var cells = 0
	var check_position = grid_position
	for i in range(100):
		check_position = check_position + Enums.direction_to_vector(direction)
		if !does_cell_exist(check_position):
			return cells
		cells += 1

func get_traversible_neighbors(grid_position: Vector2i) -> Array[Vector2i]:
	var neighbors = _obstacle_layer.get_surrounding_cells(grid_position)
	var neighbors_to_return : Array[Vector2i]

	for neighbor in neighbors:
		if is_cell_navigable(neighbor):
			neighbors_to_return.append(neighbor)
		#var cell_exists = (_floor_layer.get_cell_source_id(neighbor) != -1 and
			#_floor_layer.get_cell_atlas_coords(neighbor) != Vector2i(-1,-1))
#
		#var tile_data = _obstacle_layer.get_cell_tile_data(neighbor)
		#var cell_traversible = true # Traversible if the cell is unoccupied
		#if tile_data:
			#cell_traversible = tile_data.get_custom_data("Traversible")
		#cell_traversible = cell_traversible and not _obstacle_overrides.has(neighbor)
#
		#if cell_exists and cell_traversible:
			#neighbors_to_return.append(neighbor)

	# Your own position is traversible, too! For actions that keep you in the same square
	neighbors_to_return.append(grid_position)

	return neighbors_to_return

func is_cell_navigable(grid_position: Vector2i) -> bool:
	var cell_exists = does_cell_exist(grid_position)

	var tile_data = _obstacle_layer.get_cell_tile_data(grid_position)
	var cell_traversible = true # Traversible if the cell is unoccupied
	if tile_data:
		cell_traversible = tile_data.get_custom_data("Traversible")
	cell_traversible = cell_traversible and not _obstacle_overrides.has(grid_position)

	return cell_exists and cell_traversible

func does_cell_exist(grid_position: Vector2i) -> bool:
	return (_floor_layer.get_cell_source_id(grid_position) != -1 and
			_floor_layer.get_cell_atlas_coords(grid_position) != Vector2i(-1,-1))

func get_tile_size() -> Vector2i:
	return _floor_layer.tile_set.tile_size

func get_grid_size() -> Vector2i:
	return (_floor_layer.get_used_rect() \
		.merge(_obstacle_layer.get_used_rect())).size

## Take global coordinates and convert to map coordinates
func global_to_map(coordinates : Vector2):
	return _floor_layer.local_to_map(_floor_layer.to_local(coordinates))

func map_to_local(grid_position: Vector2i):
	return _floor_layer.map_to_local(grid_position)

func update_obstacle_grid(grid_position: Vector2i, traversible: bool):
	if traversible:
		_obstacle_overrides.erase(grid_position)
	else:
		_obstacle_overrides.append(grid_position)
	path_grid.set_point_solid(grid_position, !traversible) # update A* grid

	if get_tree().debug_collisions_hint:
		_draw_obstacle_traversibility()

func clear_obstacle_overrides() -> void:
	for override in _obstacle_overrides:
		path_grid.set_point_solid(override, false)
	_obstacle_overrides.clear()

	if get_tree().debug_collisions_hint:
		_draw_obstacle_traversibility()

func has_static_obstacle(grid_position: Vector2i) -> bool:
	return _obstacle_layer.get_used_cells().has(grid_position)

## Multiply the cost of a tile by the given `weight_scale` argument
func update_weight_grid(grid_position: Vector2i, weight_scale: float) -> void:
	path_grid.set_point_weight_scale(grid_position, weight_scale)

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
		if _obstacle_overrides.has(tile):
			continue
		if _obstacle_layer.get_cell_tile_data(tile) == null:
			continue
		if _obstacle_layer.get_cell_tile_data(tile).get_custom_data("Traversible"):
			continue
		path_grid.set_point_solid(tile)
	path_grid.update()

func _on_target_area_entered(_area: Area2D) -> void:
	target_reached.emit()

func _draw_obstacle_traversibility() -> void:
	_debug_drawing_layer.clear_data()
	for tile in _obstacle_layer.get_used_cells():
		if not _obstacle_layer.get_cell_tile_data(tile).get_custom_data("Traversible"):
			_debug_drawing_layer.rectangle_centers.append(map_to_local(tile))
	for tile in _obstacle_overrides:
		_debug_drawing_layer.rectangle_centers.append(map_to_local(tile))
	_debug_drawing_layer.queue_redraw()
