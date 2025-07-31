extends Node2D

@export var bounds : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func get_traversible_neighbors(position: Vector2i) -> Array[Vector2i]:
	var neighbors = $Obstacles.get_used_cells()
	var neighbors_to_return : Array[Vector2i]
	
	for neighbor in neighbors:
		if $Obstacles.get_cell_tile_data().get_custom_data("Traversible"):
			neighbors_to_return.append(neighbor)
		
	return neighbors_to_return
	
func get_vertical_tile_spacing():
	return $Floor.tile_set.tile_size.y
	
func get_horizontal_tile_spacing():
	return $Floor.tile_set.tile_size.x
	
