extends Area2D

class_name LaserBlocker

##The height off the ground of a laser blocker (so a laser beam could go under it if it's greater than that laser's height)
@export var altitude := 0

##The biggest distance across any dimension of a blocker. If a blocker is bigger than this, laser exit point may not be computed correctly
const MAX_DIMENSION := 100

##Raycast for getting collision exit point
@onready var ray = RayCast2D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(Enums.CollisionLayer.LASER_BLOCKER, true)
	ray.enabled = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	ray.hit_from_inside = false
	ray.exclude_parent = false
	ray.set_collision_mask_value(Enums.CollisionLayer.SELF_DETECT, true)
	add_child(ray)

func get_lowest_point_global_coordinates() -> int:
	var lowest_point = INF
	for child in get_children():
		if child is CollisionShape2D:
			# use bounding box to get lowest point in collision shape
			var new_lowest_candidate = child.global_position.y + child.shape.get_rect().end.y
			if new_lowest_candidate < lowest_point:
				lowest_point = new_lowest_candidate
	return lowest_point

func get_highest_point_global_coordinates() -> int:
	var highest_point = -INF
	for child in get_children():
		if child is CollisionShape2D:
			# use bounding box to get lowest point in collision shape
			var new_highest_candidate = child.global_position.y + child.shape.get_rect().position.y
			if new_highest_candidate > highest_point:
				highest_point = new_highest_candidate
	return highest_point

##Returns the point on the laser blocker. Collision point should be global coordinates, returned value is global
func get_collision_exit_point(collision_point: Vector2, normal: Vector2) -> Vector2:
	# Cast the ray from a point along the normal outside the area back in to find the back of the shape
	ray.global_position = collision_point - normal * MAX_DIMENSION
	#ray.global_position = collision_point - normal * .01
	ray.target_position = normal * MAX_DIMENSION
	ray.enabled = true
	set_collision_layer_value(Enums.CollisionLayer.SELF_DETECT, true)
	ray.force_raycast_update()
	set_collision_layer_value(Enums.CollisionLayer.SELF_DETECT, false)
	# Rare case that collision point was at a vertex
	var exit_point
	if ray.is_colliding():
		exit_point = ray.get_collision_point()
	else:
		exit_point = collision_point
	set_collision_layer_value(Enums.CollisionLayer.SELF_DETECT, false)
	return exit_point
