extends Area2D

class_name LaserBlocker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(Enums.CollisionLayer.LASER_BLOCKER, true)

func get_lowest_point_global_coordinates() -> int:
	var lowest_point = INF
	for child in get_children():
		if child is CollisionShape2D:
			# use bounding box to get lowest point in collision shape
			var new_lowest = child.global_position.y + child.shape.get_rect().end.y
			if new_lowest < lowest_point:
				lowest_point = new_lowest
	return lowest_point
