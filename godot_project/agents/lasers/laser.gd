@tool
extends Agent

class_name Laser

@onready var _sprite := $Sprite
@onready var collision_shape := $BeamLine/Collision/CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var sound = $SoundEmitter
@onready var beam_line = $BeamLine
@onready var beam_end = $BeamLine/BeamEnd

@export_subgroup("Instance Setup")
@export var direction := Enums.Direction.DOWN: set = set_direction
## Length of the laser beam
@export var beam_length := 100: set = set_beam_length
## Beat sequence: for each item in the array, on that beat the laser will fire/not fire
@export var activation_sequence: Array[bool] = [false, true]

@export_subgroup("Laser Data")
@export var animation_delay := 0.1
@export var beam_width := 4
@export var direction_data: Dictionary[Enums.Direction, LaserDirectionData]


func _ready() -> void:
	_construct()
	beam_line.visible = false
	tick.connect(_fire)

# Called when certain exports are changed so they can be visualized in the editor
func _construct():
	# Setters might be called before initialization
	if !is_inside_tree(): return

	# Laser visuals
	_sprite.set_animation(direction_data.get(direction).animation_name)
	beam_line.position = direction_data.get(direction).start_position_offset
	beam_line.points[1] = beam_length * direction_data.get(direction).vector_direction
	beam_line.visible = false
	beam_end.texture = direction_data.get(direction).end_image
	beam_end.position = beam_line.points[1]
	_sprite.frame = 0
	beam_line.visible = true


	# Laser collision
	var new_shape = collision_shape.shape.duplicate()
	new_shape.b = beam_line.points[1]
	collision_shape.shape = new_shape
	collision_shape.disabled = true
	
	print(collision_shape.shape.b)

func set_beam_length(new_length: int):
	beam_length = new_length
	_construct()

func set_direction(new_direction: Enums.Direction):
	direction = new_direction
	_construct()

func _fire(beat: int):
	if activation_sequence[beat % activation_sequence.size()]:
		await get_tree().create_timer(animation_delay).timeout
		sound.play()
		_sprite.play(direction_data.get(direction).animation_name)
		animation_player.play("laser_fire")
