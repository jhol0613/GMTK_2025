@tool

extends Agent

class_name Treadmill

@export var direction := Enums.Direction.UP: set = set_direction
@export var _direction_data: Dictionary[Enums.Direction, TreadmillDirectionData]

@export var _pusher: Pusher

func _construct():
	sprite.animation = _direction_data[direction].animation_name
	sprite.frame = 0
	if not Engine.is_editor_hint():
		sprite.play_with_signals(_direction_data[direction].animation_name)
		_pusher.push_action = _direction_data[direction].push_action

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_direction(direction)
	pass # Replace with function body.

func set_direction(new_direction: Enums.Direction) -> void:
	direction = new_direction
	_construct()
