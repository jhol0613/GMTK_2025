@tool
extends Agent

class_name Laser

@export_subgroup("Nodes")
@export var _sprite : AnimatedSprite2DSignals
@export var collision_area : Area2D
@export var collision_shape : CollisionShape2D
@export var animation_player : AnimationPlayer
@export var visuals : Node2D
@export var beam_line : Line2D
@export var beam_end : Sprite2D
##Determines IF an object is hit for up/left/right Origin is laser base
@export var base_raycast : RayCast2D
##Determines WHERE an object gets hit (for left/right lasers), and IF an object gets hit for down lasers. Origin coincident with visual beamline
@export var beam_raycast : RayCast2D
@export var pole1 : Sprite2D
@export var pole2 : Sprite2D
@export var shadow : AnimatedSprite2DSignals
@export var obstacle : MovableObstacle

##Height corresponding to a laser shooting out of the ground
const popup_height := 7
const pole1_height := 33
const pole2_height := 24

@export_subgroup("Instance Setup")
@export var direction := Enums.Direction.DOWN: set = set_direction
##Length of the laser beam (if it were at 0 height). If set to 0, laser will determine length using
##static level geometry. This will not prevent laser from getting cut short by laser blockers
@export var max_beam_length := 0: set = set_max_beam_length
@export_range(popup_height, popup_height + pole1_height + pole2_height, 1) var height := 7: set = _set_height

@export_subgroup("Laser Data")
##Heighest laser height value that can be jumped
@export var jumpable_threshhold := 15.0
##Lowest laser height value that can be ducked
@export var duckable_threshhold := 27.0
@export var beam_width := 4
@export var direction_data: Dictionary[Enums.Direction, LaserDirectionData]
@export var beam_end_correction_factor := Vector2i(3, 0)

##Point at which shadow changes to low deployed sprite
@export var deployed_transition := 13

var max_beam_length_vector: Vector2
# Corrects beam endpoint based on the offset between beam origin from laser direction data and cell center
var current_beam_length: Vector2

var new_height_tween: Tween

func _ready() -> void:
	super._ready()
	add_to_group("agents")
	add_to_group("lasers")
	_construct()
	_set_height(height)
	#action_executed.connect(_fire)
	_sprite.animation_finished.connect(_reset_shadow)
	_sprite.connect("animation_signal", _fire)

# Called when certain exports are changed so they can be visualized in the editor
func _construct():
	# Setters might be called before initialization
	if !is_inside_tree(): return
	
	if !Engine.is_editor_hint() and max_beam_length > 0:
		max_beam_length_vector = Vector2i(max_beam_length, max_beam_length) * \
			Enums.direction_to_vector(direction)

	# Laser visuals
	_sprite.set_animation(direction_data.get(direction).animation_name)
	default_animation = direction_data.get(direction).animation_name
	beam_end.texture = direction_data.get(direction).end_image
	_sprite.frame = 0
	beam_line.visible = Engine.is_editor_hint()

	# Laser collision
	base_raycast.target_position = max_beam_length_vector
	beam_raycast.target_position = max_beam_length_vector
	
	_update_endpoint(max_beam_length_vector)
	
	# Collision
	var new_shape = collision_shape.shape.duplicate()
	new_shape.b = beam_line.points[1]
	collision_shape.shape = new_shape
	collision_shape.disabled = true

##Endpoint should be given relative to the beam_line position
func _update_endpoint(endpoint: Vector2):
	# Visuals
	beam_line.points[1] = endpoint
	beam_end.position = beam_line.points[1]

	#Collision
	var new_shape = collision_shape.shape.duplicate()
	new_shape.b = beam_line.points[1] + Vector2(0, -int(direction == Enums.Direction.UP) * height)
	collision_shape.shape = new_shape
	collision_shape.disabled = true

##Called to set max fire distance based on static obstacles. Laser blockers can still cause this
##distance to be shorter. If limit_is_wall is true, down-pointing lasers will apply an exception so 
##that their visual range extends all the way to the train car wall
func set_max_fire_distance_by_grid_spaces(grid_spaces: int, limit_is_wall: bool):
	var down_laser_height_correction = Vector2i(0, 0)
	if max_beam_length > 0:
		return
	if direction == Enums.Direction.DOWN and limit_is_wall:
		down_laser_height_correction = Vector2i(0, height)
	var correction = beam_end_correction_factor * Enums.direction_to_vector(direction)
	max_beam_length_vector = grid_spaces * tile_size * Enums.direction_to_vector(direction) + \
		correction + down_laser_height_correction
	_construct()

func set_max_beam_length(new_length: int):
	max_beam_length = new_length
	_construct()

func set_direction(new_direction: Enums.Direction):
	direction = new_direction
	_construct()

func _fire(anim_signal_id: String):
	if anim_signal_id != "fire":
		return

	if new_height_tween:
		new_height_tween.pause()

	if height == popup_height:
		shadow.play("low")

	beam_line.global_position = _sprite.global_position + direction_data.get(direction).start_position_offset
	# Check for laser blockers
	base_raycast.enabled = true
	beam_raycast.enabled = true
	base_raycast.force_raycast_update()
	beam_raycast.force_raycast_update()
	var collision_point := max_beam_length_vector #default if there's no collision happening
	
	var hit_check_raycast: RayCast2D
	match direction:
		Enums.Direction.UP, Enums.Direction.LEFT, Enums.Direction.RIGHT:
			hit_check_raycast = base_raycast
		Enums.Direction.DOWN:
			hit_check_raycast = beam_raycast
	
	if hit_check_raycast.is_colliding():
		var blocker: LaserBlocker = hit_check_raycast.get_collider()
		var blocker_lowpoint = blocker.get_lowest_point_global_coordinates()
		var blocker_highpoint = blocker.get_highest_point_global_coordinates()
		var blocker_height = blocker_lowpoint - blocker_highpoint
		
		if height > blocker_height:
			_finish_fire(collision_point)
			return
		
		if (direction == Enums.Direction.UP or direction == Enums.Direction.DOWN):
			collision_point = hit_check_raycast.get_collision_point()
			collision_point = Vector2(collision_point.x, blocker_lowpoint - height) - beam_line.global_position
		else: #direction left or right
			if beam_raycast.is_colliding(): #should always be true since we already did a height check
				collision_point = beam_raycast.get_collision_point() - beam_line.global_position
	_finish_fire(collision_point)

	#if base_raycast.is_colliding(): #up, left, or right direction uses base raycast as a basis for whether hit occurs
		#var blocker: LaserBlocker = base_raycast.get_collider()
		#var blocker_lowpoint = blocker.get_lowest_point_global_coordinates()
		#var blocker_highpoint = blocker.get_highest_point_global_coordinates()
		#var blocker_height = blocker_lowpoint - blocker_highpoint
#
		##Does not allow for shooting over one thing and getting blocked by another. If the first thing is too short,
		##laser continues to the next static obstacle disregarding any more laser blockers
		#if height > blocker_height:
			#_finish_fire(max_beam_length_vector)
			#return
		#if (direction == Enums.Direction.UP or direction == Enums.Direction.DOWN):
			#collision_point = base_raycast.get_collision_point()
			#collision_point = Vector2(collision_point.x, blocker_lowpoint - height)
		#else: #direction is LEFT or RIGHT
			#beam_raycast.force_raycast_update()
			#if beam_raycast.is_colliding(): #should always be true since we already did a height check
				#collision_point = beam_raycast.get_collision_point()
		##if Direction is LEFT or RIGHT, just use the returned collision point since height doesn't have to be adjusted
		#_finish_fire(collision_point - beam_line.global_position)
	#elif (beam_raycast.is_colliding and direction == Enums.Direction.DOWN):
		#pass
	#else:
		#_finish_fire(max_beam_length_vector)

##Collision point should be given relative to beam_line position
func _finish_fire(collision_point: Vector2):
	_update_endpoint(collision_point)
	beam_raycast.enabled = false
	base_raycast.enabled = true

	# Fire laser property animation
	animation_player.play("laser_fire")

	if new_height_tween:
		await animation_player.animation_finished
		if new_height_tween.is_valid():
			new_height_tween.play()

##If laser is baseline height, set shadow back to stowed after laser retracts (kind of a lazy solution here)
func _reset_shadow():
	if height == popup_height:
		shadow.play("stowed")
	

func _set_height(new_height: int):
	# Gets rid of old height modifier for max_beam_length_vector and adds new height
	height = new_height
	
	if !is_inside_tree():
		return 
	
	pole1.position.y = max(-height + popup_height, -pole1_height)
	pole2.position.y = min(max(-height + pole1_height + popup_height, -pole2_height), 0)
	
	if height <= popup_height:
		shadow.play("stowed")
		obstacle.enabled = false
	elif height <= deployed_transition:
		shadow.play("low")
		obstacle.enabled = true
	else:
		shadow.play("deployed")
		obstacle.enabled = true
	if height >= duckable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, false)
	if height <= jumpable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, false)

func set_height_animated(new_height: int, duration: float):
	var old_height = height
	new_height_tween = create_tween()
	new_height_tween.tween_property(self, "height", new_height, duration)
	new_height_tween.tween_callback(_update_max_firing_distance_for_down_laser_height_change.bind(old_height))

func _update_max_firing_distance_for_down_laser_height_change(old_height: int):
	if direction == Enums.Direction.DOWN:
		var height_adjustment = Vector2((height - old_height) * Enums.direction_to_vector(Enums.Direction.DOWN))
		max_beam_length_vector = max_beam_length_vector + height_adjustment
		_construct()
