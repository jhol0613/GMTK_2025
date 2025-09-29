extends Node2D

class_name Agent

##agent's initial position in the grid
@export var grid_origin := Vector2i.ZERO

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2DSignals

## agent's position inside of the grid
var grid_position := Vector2i(0, 0)
## grid's tile size for calculating the local position
var tile_size: Vector2i
## grid origin in local coordinate space. This should be the coordinate space where position is calculated,
## i.e. local with respect to the level itself. It should include the difference between a cell's top left
## corner vice its center as well as any offset from parents (i.e. nodes between the agent and and the level
## in the node hierarchy
var local_origin := Vector2.ZERO: set = _set_local_origin
var lock_local_origin = false
## grid total size
var grid_size := Vector2i.ZERO

##Emitted for all agents on every beat (regardless of play/thinking mode)
signal tick(beat: int)

##Pass on signals from agent's animation sprite
signal animation_signal(id: String)

func _ready() -> void:
	add_to_group("agents")
	#reset()
	if sprite != null:
		sprite.connect("animation_signal", _on_animation_signal)

func reset() -> void:
	grid_position = grid_origin
	position = _grid_to_local(grid_position)

func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)
	
func _on_animation_signal(signal_id):
	animation_signal.emit(signal_id)

#only allow local origin to be set once, as required, by the level
func _set_local_origin(new_local_origin: Vector2):
	if not lock_local_origin:
		local_origin = new_local_origin
		lock_local_origin = true

func _unlock_set_local_origin():
	lock_local_origin = false
