@tool

extends Agent

class_name Treadmill

@export var direction := Enums.Direction.UP: set = set_direction
@export var _direction_data: Dictionary[Enums.Direction, TreadmillDirectionData]
@export var animation_speed := 1.0
@export var animation_loops := 2

@export var _pusher: Pusher

@onready var sound := $FmodEventEmitter2D
@onready var _animation_loop_counter := 0

func _construct():
	sprite.animation = _direction_data[direction].animation_name
	sprite.frame = 0
	if not Engine.is_editor_hint():
		#sprite.play_with_signals(_direction_data[direction].animation_name)
		_pusher.push_action = _direction_data[direction].push_action
		default_animation = _direction_data[direction].animation_name

func _ready() -> void:
	super._ready()
	set_direction(direction)
	sprite.speed_scale = animation_speed
	action_executed.connect(_on_action_executed)
	_pusher.push_beat = default_action_beat

func _on_action_executed(action):
	sprite.animation_looped.connect(_on_animation_looped)

func _on_animation_looped():
	_animation_loop_counter += 1
	if _animation_loop_counter >= animation_loops:
		sprite.stop()
		_animation_loop_counter = 0
		sprite.animation_looped.disconnect(_on_animation_looped)

func set_direction(new_direction: Enums.Direction) -> void:
	direction = new_direction
	_construct()
