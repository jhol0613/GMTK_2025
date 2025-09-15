extends Node2D

class_name Agent

# agent's initial position in the grid
@export var grid_origin := Vector2i.ZERO

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2DSignals

# agent's position inside of the grid
var grid_position := Vector2i(0, 0)
# grid's tile size for calculating the local position
var tile_size: Vector2i
# grid origin in local coordinate space to calculate local grid cell position
var local_origin := Vector2.ZERO
# grid total size
var grid_size := Vector2i.ZERO

##Emitted for all agents on every beat (regardless of play/thinking mode)
signal tick(beat: int)

##Pass on signals from agent's animation sprite
signal animation_signal(id: String)

func _ready() -> void:
	reset()
	if sprite != null:
		sprite.connect("animation_signal", _on_animation_signal)

func reset() -> void:
	grid_position = grid_origin
	position = _grid_to_local(grid_position)

func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)
	
func _on_animation_signal(signal_id):
	animation_signal.emit(signal_id)
