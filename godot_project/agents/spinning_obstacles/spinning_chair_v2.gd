@tool

extends Agent

class_name SpinningChairV2

@export_group("Instance Setup")
##Number of beats it takes for chair to rotate 90 degrees
@export var beats_per_quarter_turn := 0.3
@export var start_direction := Enums.Direction.DOWN: set = _set_start_direction
##If true, chair will only turn if commanded to do so externally (i.e. not "on the beat"
@export var terminal_controlled := true

@export_group("Spinning Chair Data")
##At runtime, actual grid size will be used to calculate pusher positions. This is for visualizing in level editor
@export var visualization_tile_size := Vector2i(32, 19)

@export_group("Nodes")
@export var left_obstacle: MovableObstacle
@export var middle_obstacle: MovableObstacle
@export var right_obstacle: MovableObstacle
@export var visual_center: VisualCenter
@onready var my_nodes = [sprite, default_sound_emitter, left_obstacle, middle_obstacle, right_obstacle, visual_center]
##Nodes that should be anchored to couch rotation. Vector2 is the initial position
var anchored_nodes: Dictionary[Node, Vector2]
var anchored_node_centers: Dictionary[Node, VisualCenter]

@onready var _left_push_action_cycle = [
	Enums.PlayerAction.UP_FALL,
	Enums.PlayerAction.RIGHT_FALL,
	Enums.PlayerAction.DOWN_FALL,
	Enums.PlayerAction.LEFT_FALL
]

@onready var _right_push_action_cycle = [
	Enums.PlayerAction.DOWN_FALL,
	Enums.PlayerAction.LEFT_FALL,
	Enums.PlayerAction.UP_FALL,
	Enums.PlayerAction.RIGHT_FALL
]

##This is so the move cursor doesn
@onready var _spin_chair_move_cursor

var _frame_timer: Timer
var _facing_direction: Enums.Direction
var _frame_increment = 1 # one for forward, -1 for backward

func _construct():
	_facing_direction = start_direction
	_update_frame(_direction_to_frame(_facing_direction))
	#_update_frame(2 * start_direction) #see enum description for why this works
	var initial_spacing
	if Engine.is_editor_hint():
		initial_spacing = visualization_tile_size
	else:
		#should be getting tile_size from level manager, but this gets called before initialization 
		#and non-movables don't get their tile_size initialized until later, so this is unfortunately way easier
		initial_spacing = visualization_tile_size 

	#Set starting positions for left and right pushers
	match _facing_direction:
		Enums.Direction.DOWN:#, FacingDirection.FRONT_COUNTERCLOCKWISE:
			left_obstacle.global_position = Vector2(middle_obstacle.global_position.x - initial_spacing.x, middle_obstacle.global_position.y)
			right_obstacle.global_position = Vector2(middle_obstacle.global_position.x + initial_spacing.x, middle_obstacle.global_position.y)
		Enums.Direction.UP:
			right_obstacle.global_position = Vector2(middle_obstacle.global_position.x - initial_spacing.x, middle_obstacle.global_position.y)
			left_obstacle.global_position = Vector2(middle_obstacle.global_position.x + initial_spacing.x, middle_obstacle.global_position.y)
		Enums.Direction.LEFT:
			left_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y - initial_spacing.y)
			right_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y + initial_spacing.y)
		Enums.Direction.RIGHT:
			left_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y + initial_spacing.y)
			right_obstacle.position = Vector2(middle_obstacle.position.x, middle_obstacle.position.y - initial_spacing.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_construct()
	#add_to_group("movable_obstacles") #This is so reset code gets called when play button pressed

	left_obstacle.set_move_cursor_start_position(direction_to_move_cursor_position(_facing_direction))
	right_obstacle.set_move_cursor_start_position(direction_to_move_cursor_position(_facing_direction))

	left_obstacle.standard_move_data.move_duration = AudioManager.beat_time_seconds * beats_per_quarter_turn
	right_obstacle.standard_move_data.move_duration = AudioManager.beat_time_seconds * beats_per_quarter_turn

	#if not terminal_controlled:
		#left_obstacle.action_executed.connect(_on_left_obstacle_move)
		#right_obstacle.action_executed.connect(_on_right_obstacle_move)

	_frame_timer = Timer.new()
	_frame_timer.one_shot = true
	_frame_timer.timeout.connect(_advance_sprite_frame)
	add_child(_frame_timer)

	for child in get_children():
		if not my_nodes.has(child) and child is  Node2D:
			#Store positions as the relative position from spin chair's vis center to child's visual center (if it has one)
			anchored_nodes[child] = _get_visual_center_position(child)

func direction_to_move_cursor_position(direction: Enums.Direction) -> int:
	match direction:
		Enums.Direction.DOWN:
			return 0
		Enums.Direction.LEFT:
			return 1
		Enums.Direction.UP:
			return 2
		Enums.Direction.RIGHT:
			return 3
		_:
			return 0

##Use this instead of updating frame directly so that anchored nodes also get moved
func _update_frame(new_sprite_frame: int):
	var child_rotation
	if new_sprite_frame == sprite.frame:
		child_rotation = 0.0
	elif [1, 2, 7, 0].has(new_sprite_frame): #counterclockwise frames
		child_rotation = PI / 4.0
		#rotate clockwise
	elif [3, 4, 5, 6].has(new_sprite_frame): #clockwise frames
		child_rotation = - PI / 4.0

	sprite.frame = new_sprite_frame

	if not anchored_nodes:
		return
	for child in anchored_nodes:
		pass
#		_set_position_based_on_visual_center(child, _get_visual_center_position(child).rotated(child_rotation))

# Bypass agent's animation system with override
func _on_animation_start(action):
	pass

# Bypass agent's sound system with override
func _on_sound_start(action):
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
	_update_frame(posmod((sprite.frame + _frame_increment), sprite.sprite_frames.get_frame_count(sprite.animation)))

func _set_start_direction(new_direction: Enums.Direction):
	start_direction = new_direction
	_construct()
	left_obstacle.set_move_cursor_start_position(direction_to_move_cursor_position(start_direction))
	right_obstacle.set_move_cursor_start_position(direction_to_move_cursor_position(start_direction))
	
##Returns position of a Node's visual center relative to this Spinning Chair. Uses the node's base
##position if there is no visual center defined
func _get_visual_center_position(node: Node2D) -> Vector2:
	for child in node.get_children():
		if child is VisualCenter:
			return child.global_position - visual_center.global_position
	return node.global_position - visual_center.global_position

func _get_visual_center(node: Node2D) -> VisualCenter:
	for child in node.get_children():
		if child is VisualCenter:
			return child
	return null

##Give new_position in terms of what you want the visual center's position to be
func _set_position_based_on_visual_center(node: Node2D, new_position: Vector2):
	var old_position = _get_visual_center_position(node)
	var child_vis_center = _get_visual_center(node)
	if child_vis_center:
		node.position = new_position + visual_center.position - child_vis_center.position
	else:
		node.position = new_position + visual_center.position
	#I don't love this, I shouldn't be accounting for different types of another agent in an agent class
	if node is Interactable:
		node.updated_position.emit(node, node.global_position)
		#If new and old signs are different, flip the interactable (can't just multiply to check sign flip
		#or it will flip twice if the hy value stops on exactly 0 for a frame)
		if (new_position.y > 0 and old_position.y <= 0) or (new_position.y < 0 and old_position.y >= 0):
			node.flip_horizontal = not node.flip_horizontal

##Positive for clockwise, negative for counterclockwise
func spin(number_of_quarter_turns: int = 1, update_origin = false):
	var range = range(number_of_quarter_turns) if number_of_quarter_turns >=0 else range(0, number_of_quarter_turns, -1)
	for i in range:
		# Go back a step in the move sequence if turning counterclockwise
		if number_of_quarter_turns < 0:
			#Update move cursor, request the action in sequence, then update move cursor again to sync to new chair position
			left_obstacle._move_cursor = posmod(left_obstacle._move_cursor + 1, left_obstacle.movement_path.size())
			
			right_obstacle._move_cursor = posmod(right_obstacle._move_cursor + 1, right_obstacle.movement_path.size())

			_frame_increment = -1
		else:
			_frame_increment = 1
		left_obstacle.request_offbeat_action.emit(left_obstacle, left_obstacle.get_next_move(), update_origin)
		right_obstacle.request_offbeat_action.emit(right_obstacle, right_obstacle.get_next_move(), update_origin)
		#update move cursor again to stay in sync with visuals if rotating counterclockwise
		if number_of_quarter_turns < 0:
			left_obstacle._move_cursor = posmod(left_obstacle._move_cursor + 1, left_obstacle.movement_path.size())
			right_obstacle._move_cursor = posmod(right_obstacle._move_cursor + 1, right_obstacle.movement_path.size())
		_on_left_obstacle_move(Enums.PlayerAction.NONE)
		_on_right_obstacle_move(Enums.PlayerAction.NONE)
		if number_of_quarter_turns < 0:
			left_obstacle.pusher.push_action = _left_push_action_cycle[left_obstacle._move_cursor -2]
			right_obstacle.pusher.push_action = _right_push_action_cycle[right_obstacle._move_cursor-2]
		_facing_direction = Enums.rotate_90_right(_facing_direction) if number_of_quarter_turns >= 0 \
			else Enums.rotate_90_left(_facing_direction)
		await _frame_timer.timeout
	$FmodEventEmitter2D.play()

##Because arg is a direction and not a facing direction, will always return the smallest # quarter
##turns. Positive is clockwise, negative is counterclockwise
func get_quarter_turns_to_direction(direction: Enums.Direction) -> int:
	var temp_direction = direction
	# this code is so bad
	for i in range(2): #Start by checking 180 counterclockwise
		direction = Enums.rotate_90_left(direction)
	for i in range(4): #check directions, rotating a quarter turn each check
		if direction == _facing_direction:
			return i - 2
		direction = Enums.rotate_90_right(direction)
	return 0

func get_direction() -> Enums.Direction:
	return _facing_direction

func _direction_to_frame(direction: Enums.Direction)->int:
	match direction:
		Enums.Direction.RIGHT:
			return 0
		Enums.Direction.DOWN:
			return 2
		Enums.Direction.LEFT:
			return 4
		Enums.Direction.UP:
			return 6
		_:
			return 0

func reset():
	super.reset()
	# Don't call super so position of the chair doesn't reset
	_facing_direction = start_direction
	if _frame_timer != null:
		_frame_timer.stop() #prevent frame from getting off by one if reset in the middle of rotate animation
	# Reset child positions
	_construct()
	for child in anchored_nodes.keys():
		_set_position_based_on_visual_center(child, anchored_nodes[child])
		#child.position = anchored_nodes[child]
