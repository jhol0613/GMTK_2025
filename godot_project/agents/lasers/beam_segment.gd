extends RayCast2D

class_name BeamSegment

##If beam total length hits beam_end_length, no more beams will be spawned
var beam_end_length := 1000.0 : set = set_beam_end_length
##If beam hits max beam length, it will only go this far but it will spawn another beam
var max_beam_length := beam_end_length : set = set_max_beam_length
var direction: Enums.Direction
var height: int : set = set_height
##Previous length of all beam segments up to the start of this one
var previous_length: float
@onready var line := $BeamLine
var self_scene : Resource
var beam_end_texture : CompressedTexture2D
#Distance to offset segment start visuals
var line_offset : Vector2
var child: BeamSegment
##Whether or not this beam should fire recursively again if there's not collision. For example, this would be
##true for beam segments that go through blockers up to the blocker endpoint, or for up-pointing lasers for the
##initial invisible beam segment
var fire_again_on_no_hit = false

const jostle_amount := .01
#Just setting beam height to laser height is off by a few pixels
const horizontal_laser_height_offset = 3

#TODO: If laser blockers are ever something besides a rectangle, we will need 2 raycasts, one for sensing and 
#one for determining where to split the beam

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_height(height)

func setup(new_direction: Enums.Direction, new_height: int, new_previous_length: float, 
	preloaded_self_scene: Resource, new_beam_end_texture: CompressedTexture2D, new_line_offset := Vector2(0,0)):
	direction = new_direction
	height = new_height
	previous_length = new_previous_length
	self_scene = preloaded_self_scene
	line_offset = new_line_offset
	beam_end_texture = new_beam_end_texture

func set_height(new_height: int) -> void:
	height = new_height
	if not Enums.is_vertical(direction) and line:
		line.position.y = -height + horizontal_laser_height_offset
	#if line:
		#line.position = Vector2(0, -height) + line_offset

func set_beam_end_length(new_beam_end_length):
	beam_end_length = new_beam_end_length
	_refresh_target()

func set_max_beam_length(new_max_beam_length):
	max_beam_length = new_max_beam_length
	_refresh_target()

func _refresh_target():
	var beam_end_limited = (beam_end_length - previous_length) <= max_beam_length
	if beam_end_limited:
		target_position = Enums.direction_to_vector(direction) * (beam_end_length - previous_length)
	else:
		target_position = Enums.direction_to_vector(direction) * max_beam_length

# returns the position where the fire ended (e.g. for the purpose of drawing laser endpoint)
func fire(depth: int):# -> Vector2:
	var should_spawn_child = false
	print("depth: ", depth)
	enabled = true
	force_raycast_update()
	var collision_point : Vector2 #Global coordinates
	var return_point : Vector2
	
	if is_colliding():
		collision_point = get_collision_point()
	elif fire_again_on_no_hit:
		collision_point = target_position + global_position
		should_spawn_child = true
	else: #hits beam end
		line.points[1] = target_position
		var beam_end = Sprite2D.new()
		beam_end.texture = beam_end_texture
		beam_end.position = line.points[1] + Vector2(0, -horizontal_laser_height_offset)
		beam_end.z_index = -1
		add_child(beam_end)
		return# line.points[1] + line.global_position
		
	line.points[1] = collision_point - global_position
	child = self_scene.instantiate()
	child.setup(direction, height, previous_length + _quick_distance(collision_point, global_position), 
		self_scene, beam_end_texture)
	add_child(child)
	child.position = _jostle(line.points[1], Enums.direction_to_vector(direction))
	child.beam_end_length = beam_end_length
	child.z_index = -z_index #start child z-index at parent's baseline
	if get_tree().debug_collisions_hint: #in debug mode, make different laser segments distinct
		child.modulate = Color(randf(), randf(), randf(), 1.0)

	if is_colliding():
		# Case 2: Laser encounters blocker
		var blocker: LaserBlocker = get_collider()
		var blocker_lowpoint = blocker.get_lowest_point_global_coordinates()
		var blocker_highpoint = blocker.get_highest_point_global_coordinates()
		var blocker_height = blocker_lowpoint - blocker_highpoint + blocker.altitude

		if height <= blocker_height + blocker.altitude and height >= blocker.altitude: #laser blocked
			if (direction == Enums.Direction.UP or direction == Enums.Direction.DOWN):
				collision_point = Vector2(collision_point.x, blocker_lowpoint - height + blocker.altitude)
		else:
			var blocker_exit_point = blocker.get_collision_exit_point(collision_point, get_collision_normal())
			child.max_beam_length = _quick_distance(blocker_exit_point, line.global_position + line.points[1])
			child.fire_again_on_no_hit = true
			should_spawn_child = true
			
			if height > blocker_height:
				child.z_index += 1
			else:
				child.z_index -= 1
			

		#else: #direction left or right
			#if hit_check_raycast.is_colliding(): #should always be true since we already did a height check
				#collision_point = get_collision_point()# - beam_line.global_position
	#if fire_again:
	if should_spawn_child:
		child.fire(depth + 1)
	
	# Case 3: Laser reaches end of blocker
	collision_point = collision_point - global_position #de-globalize collision point
	#await get_tree().create_timer(1.0).timeout
	#child.queue_free()
	_destroy_after_time(child, 1.0)
	return# return_point

#time in seconds
func _destroy_after_time(node: Node2D, time: float):
	await get_tree().create_timer(1.0).timeout
	node.queue_free()

##Distance to points that share an axis coordinate
func _quick_distance(point1: Vector2, point2: Vector2) -> float:
	var offset = point1 - point2
	if Enums.is_vertical(direction):
		return abs(offset.y)
	else:
		return abs(offset.x)
		
##Move point slightly in direction of collision normal so infinite hits aren't triggered
func _jostle(point: Vector2, normal: Vector2) -> Vector2:
	return point + normal * jostle_amount
