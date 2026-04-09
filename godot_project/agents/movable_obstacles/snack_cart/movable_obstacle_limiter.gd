extends Line2D

class_name MovableObstacleLimiter

var global_points : PackedVector2Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_points.resize(points.size())

##Pass destination in global coordinates
func is_destination_in_bounds(point: Vector2):
	return Geometry2D.is_point_in_polygon(point, global_points)

##Obstacle global position is its global position prior to a potential action.
func get_allowed_directions(obstacle_global_position: Vector2, tile_size: Vector2i) -> Dictionary[Enums.Direction, bool]:
	_refresh_global_points()
	var allowed_directions : Dictionary[Enums.Direction, bool] = {
		Enums.Direction.UP: false,
		 Enums.Direction.DOWN: false,
		 Enums.Direction.LEFT: false,
		 Enums.Direction.RIGHT: false
	}
	for direction in allowed_directions.keys():
		allowed_directions[direction] = is_destination_in_bounds(Vector2i(obstacle_global_position) + \
		Enums.direction_to_vector(direction) * tile_size)
	return allowed_directions

func is_direction_allowed(obstacle_global_position: Vector2, direction: Enums.Direction, tile_size: Vector2i) -> bool:
	_refresh_global_points()
	var in_bounds = is_destination_in_bounds(Vector2i(obstacle_global_position) + \
		Enums.direction_to_vector(direction) * tile_size)
	return in_bounds

func _refresh_global_points():
	for i in range(points.size()):
		global_points[i] = points[i] + global_position
