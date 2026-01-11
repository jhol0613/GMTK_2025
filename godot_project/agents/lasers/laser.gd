@tool
extends Agent

class_name Laser

@export_subgroup("Nodes")
@export var _sprite : AnimatedSprite2DSignals
@export var collision_area : Area2D
@export var collision_shape : CollisionShape2D
@export var animation_player : AnimationPlayer
@export var beam_line : Line2D
@export var beam_end : Sprite2D
@export var raycast : RayCast2D
@export var pole1 : Sprite2D
@export var pole2 : Sprite2D
@export var shadow : AnimatedSprite2DSignals

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
	action_executed.connect(_fire)
	_sprite.animation_finished.connect(_reset_shadow)

# Called when certain exports are changed so they can be visualized in the editor
func _construct():
	# Setters might be called before initialization
	if !is_inside_tree(): return

	# Laser visuals
	_sprite.set_animation(direction_data.get(direction).animation_name)
	default_animation = direction_data.get(direction).animation_name
	beam_end.texture = direction_data.get(direction).end_image
	_sprite.frame = 0
	beam_line.visible = Engine.is_editor_hint()

	# Laser collision
	raycast.target_position = max_beam_length_vector
	
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
	
	## Collision
	#var new_shape = collision_shape.shape.duplicate()
	#new_shape.b = beam_line.points[1]
	#collision_shape.shape = new_shape
	#collision_shape.disabled = true
	
func set_max_fire_distance_by_grid_spaces(grid_spaces: int):
	##Don't use level geometry if max beam length is manually set
	if max_beam_length > 0:
		return
	var correction = beam_end_correction_factor * Enums.direction_to_vector(direction)
	max_beam_length_vector = grid_spaces * tile_size * Enums.direction_to_vector(direction) + \
		correction
	_construct()

func set_max_beam_length(new_length: int):
	max_beam_length = new_length
	if !Engine.is_editor_hint():
		max_beam_length_vector = Vector2i(max_beam_length, max_beam_length + height) * \
			Enums.direction_to_vector(direction)
	_construct()

func set_direction(new_direction: Enums.Direction):
	direction = new_direction
	_construct()

func _fire(_beat: int):
	if new_height_tween:
		new_height_tween.pause()
		
	if height == popup_height:
		shadow.play("low")
	
	beam_line.global_position = _sprite.global_position + direction_data.get(direction).start_position_offset
	# Check for laser blockers
	raycast.enabled = true
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var blocker: LaserBlocker = raycast.get_collider()
		var blocker_lowpoint = blocker.get_lowest_point_global_coordinates()
		var blocker_highpoint = blocker.get_highest_point_global_coordinates()
		# If laser shooting vertically and laser is shorter than blocker, take height into account
		if (direction == Enums.Direction.UP or direction == Enums.Direction.DOWN) \
		and (blocker_lowpoint - blocker_highpoint > height):
			collision_point = Vector2(collision_point.x, blocker_lowpoint - height)
		#if Direction is LEFT or RIGHT, just use the returned collision point since height doesn't have to be adjusted
			_update_endpoint(collision_point - beam_line.global_position)
			raycast.enabled = false
			animation_player.play("laser_fire")
			return
	_update_endpoint(max_beam_length_vector)
	raycast.enabled = false
	
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
	elif height <= deployed_transition:
		shadow.play("low")
	else:
		shadow.play("deployed")
		
	if height >= duckable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, false)
	if height <= jumpable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, false)

func set_height_animated(new_height: int, duration: float):
	new_height_tween = create_tween()
	new_height_tween.tween_property(self, "height", new_height, duration)
