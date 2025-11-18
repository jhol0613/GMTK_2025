@tool
extends Agent

class_name Laser

@onready var _sprite := $Sprite
@onready var collision_area := $BeamLine/Collision
@onready var collision_shape := $BeamLine/Collision/CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var sound = $SoundEmitter
@onready var beam_line = $BeamLine
@onready var beam_end = $BeamLine/BeamEnd
@onready var height_label = $HeightLabel

@export_subgroup("Instance Setup")
@export var direction := Enums.Direction.DOWN: set = set_direction
## Length of the laser beam
@export var beam_length := 100: set = set_beam_length
@export var height := 4.0: set = _set_height

@export_subgroup("Laser Data")
##Heighest laser height value that can be jumped
@export var jumpable_threshhold := 7.0
##Lowest laser height value that can be ducked
@export var duckable_threshhold := 27.0
@export var beam_width := 4
@export var direction_data: Dictionary[Enums.Direction, LaserDirectionData]

@onready var max_fire_distance: Vector2i

func _ready() -> void:
	super._ready()
	add_to_group("agents")
	add_to_group("lasers")
	_construct()
	_set_height(height)
	beam_line.visible = false
	action_executed.connect(_fire)

# Called when certain exports are changed so they can be visualized in the editor
func _construct():
	# Setters might be called before initialization
	if !is_inside_tree(): return

	# Laser visuals
	_sprite.set_animation(direction_data.get(direction).animation_name)
	default_animation = direction_data.get(direction).animation_name
	#beam_line.position = direction_data.get(direction).start_position_offset
	#beam_line.points[1] = beam_length * direction_data.get(direction).vector_direction
	beam_line.visible = false
	beam_end.texture = direction_data.get(direction).end_image
	#beam_end.position = beam_line.points[1]
	_sprite.frame = 0
	beam_line.visible = true

	# Laser collision
	#var new_shape = collision_shape.shape.duplicate()
	#new_shape.b = beam_line.points[1]
	#collision_shape.shape = new_shape
	#collision_shape.disabled = true
	
# Max fire distance, in number of grid spaces (actual fire distance will be less if beam encounters a blocker
func set_max_fire_distance(grid_spaces: int):
	max_fire_distance = grid_spaces * tile_size * Enums.direction_to_vector(direction)
	beam_line.position = direction_data.get(direction).start_position_offset
	beam_line.points[1] = Vector2(max_fire_distance)
	beam_end.position = beam_line.points[1]
	
	var new_shape = collision_shape.shape.duplicate()
	new_shape.b = beam_line.points[1]
	collision_shape.shape = new_shape
	collision_shape.disabled = true
	#_construct()

func set_beam_length(new_length: int):
	pass
	#beam_length = new_length
	#_construct()

func set_direction(new_direction: Enums.Direction):
	direction = new_direction
	_construct()

func _fire(beat: int):
	animation_player.play("laser_fire")

func _set_height(new_height: float):
	height = new_height
	$HeightLabel.text = str(height)
	
	if !is_inside_tree():
		return 
		
	if height >= duckable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.DUCKABLE, false)
	if height <= jumpable_threshhold:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, true)
	else:
		collision_area.set_collision_layer_value(Enums.CollisionLayer.JUMPABLE, false)
		
