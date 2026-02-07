@tool
extends Agent

class_name Laser

@export_subgroup("Nodes")
@export var _sprite : AnimatedSprite2DSignals
@export var animation_player : AnimationPlayer
@export var visuals : Node2D
@export var beam_root : BeamSegment
@export var pole1 : Sprite2D
@export var pole2 : Sprite2D
@export var shadow : AnimatedSprite2DSignals
@export var obstacle : MovableObstacle
#Clips base of laser visuals so you don't see them through laser body if laser changes its draw order due to hitting something
@export var up_laser_clipper : TextureRect

##Height corresponding to a laser shooting out of the ground
const popup_height := 7
const pole1_height := 33
const pole2_height := 24

@export_subgroup("Instance Setup")
@export var direction := Enums.Direction.DOWN: set = set_direction
##Length of the laser beam (if it were at 0 height). If set to 0, laser will determine length using
##static level geometry. This will not prevent laser from getting cut short by laser blockers
#TODO: Manual max beam length setting no longer supported in recursisve lasers. Re-implement this feature
#if we need it.
#@export var max_beam_length := 0: set = set_max_beam_length
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

#var max_beam_length_vector: Vector2

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
	
	#if !Engine.is_editor_hint() and max_beam_length > 0:
		#max_beam_length_vector = Vector2i(max_beam_length, max_beam_length) * \
			#Enums.direction_to_vector(direction)

	# Laser visuals
	_sprite.set_animation(direction_data.get(direction).animation_name)
	default_animation = direction_data.get(direction).animation_name
	_sprite.frame = 0

##Called to set max fire distance based on static obstacles. Laser blockers can still cause this
##distance to be shorter. If limit_is_wall is true, down-pointing lasers will apply an exception so 
##that their visual range extends all the way to the train car wall
func set_max_fire_distance_by_grid_spaces(grid_spaces: int, limit_is_wall: bool):
	
	## New using beam root ------------------------------------------------------------------------
	if direction == Enums.Direction.UP:
		beam_root.beam_end_length = grid_spaces * tile_size.y + .3 * tile_size.y + height
	elif direction == Enums.Direction.DOWN:
		beam_root.beam_end_length = grid_spaces * tile_size.y + height - 5
	else:
		beam_root.beam_end_length = grid_spaces * tile_size.x + .5 * tile_size.x# + beam_end_correction_factor.x
	#if direction == Enums.Direction.DOWN and limit_is_wall:
		#beam_root.beam_end_length += height
	#----------------------------------------------------------------------------------------------
	#
	#var down_laser_height_correction = Vector2i(0, 0)
	#if max_beam_length > 0:
		#return
	#if direction == Enums.Direction.DOWN and limit_is_wall:
		#down_laser_height_correction = Vector2i(0, height)
	#var correction = beam_end_correction_factor * Enums.direction_to_vector(direction)
	#max_beam_length_vector = grid_spaces * tile_size * Enums.direction_to_vector(direction) + \
		#correction + down_laser_height_correction
	_construct()

#func set_max_beam_length(new_length: int):
	#max_beam_length = new_length
	#_construct()

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
	
	beam_root.fire(0)

	_finish_fire()

#func _is_point_in_area(point: Vector2, area: Area2D):
	#var query := PhysicsPointQueryParameters2D.new()
	#query.position = point
	#query.collide_with_areas = true
	#query.collide_with_bodies = false
	#query.collision_mask = area.collision_layer
#
	#for hit in area.get_world_2d().direct_space_state.intersect_point(query):
		#if hit.collider == area:
			#return true
	#return false

#func _get_absolute_z_index(target: Node2D) -> int:
	#var node = target
	#var z_index = 0
	#while node and node.is_class('Node2D'):
		#z_index += node.z_index
		#if !node.z_as_relative:
			#break;
		#node = node.get_parent();
	#return z_index;

##Collision point should be given in global position
func _finish_fire():#beam1_endpoint: Vector2, beam2_endpoint: Vector2, beam3_endpoint: Vector2):
	#_update_endpoint(beam1_endpoint, beam2_endpoint, beam3_endpoint)
	#beam_raycast.enabled = false
	#base_raycast.enabled = true

	# Fire laser property animation
	animation_player.play("laser_fire")
	
	print(beam_root.get_child_count())

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
	
	#Set up beam
	var beam_segment_scene = preload('res://agents/lasers/beam_segment.tscn')
	beam_root.setup(direction, height, 0.0, beam_segment_scene, direction_data.get(direction).end_image)
	#this should all be packaged into a function that can be called when height/direction changes
	if direction == Enums.Direction.UP:
		up_laser_clipper.position.y = -up_laser_clipper.size.y - height + direction_data.get(direction).start_position_offset.y
		beam_root.global_position = global_position
	elif direction == Enums.Direction.DOWN:
		#new down laser strategy: hit checks will start from laser head, but will ignore the hit if 
		#bottom of collider is above it. Also needs to hit from inside.
		up_laser_clipper.position.y = -height - 10#10 is arbitrary, just to maker sure everything's in frame
		beam_root.global_position = global_position + Vector2(0, -height + direction_data.get(direction).start_position_offset.y) #laser head position
	else:
		beam_root.max_beam_length = abs(direction_data.get(direction).start_position_offset.x)
		beam_root.fire_again_on_no_hit = true
		beam_root.line.visible = false
		up_laser_clipper.position.y = -up_laser_clipper.size.y + 10#10 is arbitrary, just to maker sure everything's in frame
		beam_root.global_position = global_position + Vector2(0, -height + 2) #laser head position

func set_height_animated(new_height: int, duration: float):
	var old_height = height
	new_height_tween = create_tween()
	new_height_tween.tween_property(self, "height", new_height, duration)
	#new_height_tween.tween_callback(_update_max_firing_distance_for_down_laser_height_change.bind(old_height))

#func _update_max_firing_distance_for_down_laser_height_change(old_height: int):
	#if direction == Enums.Direction.DOWN:
		#var height_adjustment = Vector2((height - old_height) * Enums.direction_to_vector(Enums.Direction.DOWN))
		#max_beam_length_vector = max_beam_length_vector + height_adjustment
		#_construct()
