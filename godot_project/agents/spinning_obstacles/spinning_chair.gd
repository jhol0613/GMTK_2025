@tool

extends MovableObstacle

class_name SpinningChair

##Enum int values also correspond to the corresponding move cursor position for the linked moving obstacles
##Corresponding frame number should be double the enum int values
enum FacingDirection {
	##Front facing, next move is clockwise
	FRONT_CLOCKWISE,
	LEFT,
	##Front facing, next move is counterclockwise
	FRONT_COUNTERCLOCKWISE,
	RIGHT
}

@export_group("Instance Setup")
##Number of beats it takes for chair to rotate 90 degrees
@export var beats_per_quarter_turn := 1.0
@export var start_direction := FacingDirection.FRONT_CLOCKWISE: set = _set_start_direction
##If true, chair will only turn if commanded to do so externally (i.e. not "on the beat"
@export var terminal_controlled := true

@export_group("Spinning Chair Data")
##At runtime, actual grid size will be used to calculate pusher positions. This is for visualizing in level editor
@export var visualization_tile_size := Vector2i(32, 19)

@export_group("Nodes")
@export var left_obstacle: MovableObstacle
@export var middle_obstacle: MovableObstacle
@export var right_obstacle: MovableObstacle


#@onready var _left_move_cycle = [
	#Enums.PlayerAction.UP_RIGHT,
	#Enums.PlayerAction.DOWN_LEFT,
	#Enums.PlayerAction.DOWN_RIGHT,
	#Enums.PlayerAction.UP_LEFT
#]

@onready var _left_push_action_cycle = [
	Enums.PlayerAction.RIGHT_FALL,
	Enums.PlayerAction.DOWN_FALL,
	Enums.PlayerAction.RIGHT_FALL,
	Enums.PlayerAction.UP_FALL
]

#@onready var _right_move_cycle = [
	#Enums.PlayerAction.DOWN_LEFT,
	#Enums.PlayerAction.UP_RIGHT,
	#Enums.PlayerAction.UP_LEFT,
	#Enums.PlayerAction.DOWN_RIGHT
#]

@onready var _right_push_action_cycle = [
	Enums.PlayerAction.LEFT_FALL,
	Enums.PlayerAction.UP_FALL,
	Enums.PlayerAction.LEFT_FALL,
	Enums.PlayerAction.DOWN_FALL
]

##This is so the move cursor doesn
@onready var _spin_chair_move_cursor

var _frame_timer: Timer
var _facing_direction: FacingDirection

func _construct():
	_facing_direction = start_direction
	sprite.frame = 2 * start_direction #see enum description for why this works
	var initial_spacing
	if Engine.is_editor_hint():
		initial_spacing = visualization_tile_size
	else:
		initial_spacing = tile_size

	#Set starting positions for left and right pushers
	match _facing_direction:
		FacingDirection.FRONT_CLOCKWISE, FacingDirection.FRONT_COUNTERCLOCKWISE:
			left_obstacle.global_position = Vector2(middle_obstacle.global_position.x - initial_spacing.x, middle_obstacle.global_position.y)
			right_obstacle.global_position = Vector2(middle_obstacle.global_position.x + initial_spacing.x, middle_obstacle.global_position.y)
		FacingDirection.LEFT:
			left_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y - initial_spacing.y)
			right_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y + initial_spacing.y)
		FacingDirection.RIGHT:
			left_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y + initial_spacing.y)
			right_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y - initial_spacing.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_construct()
	super._ready()
	#add_to_group("movable_obstacles") #This is so reset code gets called when play button pressed
	
	left_obstacle.set_move_cursor_start_position(_facing_direction)
	right_obstacle.set_move_cursor_start_position(_facing_direction)
	
	left_obstacle.standard_move_data.move_duration = AudioManager.beat_time_seconds * beats_per_quarter_turn
	right_obstacle.standard_move_data.move_duration = AudioManager.beat_time_seconds * beats_per_quarter_turn
	
	if not terminal_controlled:
		left_obstacle.action_executed.connect(_on_left_obstacle_move)
		right_obstacle.action_executed.connect(_on_right_obstacle_move)
	
	_frame_timer = Timer.new()
	_frame_timer.one_shot = true
	_frame_timer.timeout.connect(_advance_sprite_frame)
	add_child(_frame_timer)

# Bypass agent's animation system
func _on_animation_start(action):
	pass

func _on_left_obstacle_move(_action: Enums.PlayerAction):
	# change sprite frame on obstacle move. The fact that it's left obstacle is arbitrary
	_advance_sprite_frame()
	_frame_timer.start(AudioManager.beat_time_seconds * beats_per_quarter_turn)
	
	left_obstacle.pusher.push_action = _left_push_action_cycle[left_obstacle._move_cursor]
	
func _on_right_obstacle_move(_action: Enums.PlayerAction):
	right_obstacle.pusher.push_action = _right_push_action_cycle[right_obstacle._move_cursor]
	
func _on_halfway_through_move(obstacle: MovableObstacle, new_action: Enums.PlayerAction):
	obstacle.pusher.push_action = new_action
	
func _advance_sprite_frame():
	sprite.frame = (sprite.frame + 1) % sprite.sprite_frames.get_frame_count(sprite.animation)
	
func _set_start_direction(new_direction: FacingDirection):
	start_direction = new_direction
	_construct()
	
func spin():
	left_obstacle.request_offbeat_action.emit(left_obstacle, left_obstacle.get_next_move())
	right_obstacle.request_offbeat_action.emit(right_obstacle, right_obstacle.get_next_move())
	_on_left_obstacle_move(Enums.PlayerAction.NONE)
	_on_right_obstacle_move(Enums.PlayerAction.NONE)
	
func reset():
	super.reset()
	# Don't call super so position of the chair doesn't reset
	_facing_direction = start_direction
	if _frame_timer != null:
		_frame_timer.stop() #prevent frame from getting off by one if reset in the middle of rotate animation
	_construct()
