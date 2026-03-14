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
@export var beats_per_quarter_turn := 2.0
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
@export var visual_center: VisualCenter
@onready var my_nodes = [sprite, default_sound_emitter, left_obstacle, middle_obstacle, right_obstacle, visual_center]
##Nodes that should be anchored to couch rotation. Vector2 is the initial position
var anchored_nodes: Dictionary[Node, Vector2]
var anchored_node_centers: Dictionary[Node, VisualCenter]

@onready var _left_push_action_cycle = [
	Enums.PlayerAction.RIGHT_FALL,
	Enums.PlayerAction.DOWN_FALL,
	Enums.PlayerAction.RIGHT_FALL,
	Enums.PlayerAction.UP_FALL
]

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
	_update_frame(2 * start_direction) #see enum description for why this works
	#sprite.frame = 2 * start_direction
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

	for child in get_children():
		if not my_nodes.has(child) and child is  Node2D:
			#Store positions as the relative position from spin chair's vis center to child's visual center (if it has one)
			anchored_nodes[child] = _get_visual_center_position(child)

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
		_set_position_based_on_visual_center(child, _get_visual_center_position(child).rotated(child_rotation))
		#child.position = child.position.rotated(child_rotation) - offset

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
	_update_frame((sprite.frame + 1) % sprite.sprite_frames.get_frame_count(sprite.animation))
	#sprite.frame = (sprite.frame + 1) % sprite.sprite_frames.get_frame_count(sprite.animation)

func _set_start_direction(new_direction: FacingDirection):
	start_direction = new_direction
	_construct()

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

func spin(number_of_quarter_turns: int = 1):
	for i in range(number_of_quarter_turns):
		left_obstacle.request_offbeat_action.emit(left_obstacle, left_obstacle.get_next_move())
		right_obstacle.request_offbeat_action.emit(right_obstacle, right_obstacle.get_next_move())
		_on_left_obstacle_move(Enums.PlayerAction.NONE)
		_on_right_obstacle_move(Enums.PlayerAction.NONE)
		_facing_direction += number_of_quarter_turns
		_facing_direction %= FacingDirection.size()
		await _frame_timer.timeout
	$FmodEventEmitter2D.play()

##Because arg is a direction and not a facing direction, will always return the smallest # quarter
##turns (e.g. if facing direction is LEFT and direction is DOWN, assumes the direction "down" translates to FRONT_COUNTERCLOCKWISE)
func get_quarter_turns_to_direction(direction: Enums.Direction) -> int:
	match direction:
		Enums.Direction.LEFT:
			return posmod(FacingDirection.LEFT - _facing_direction, FacingDirection.size())
		Enums.Direction.RIGHT:
			return posmod(FacingDirection.RIGHT - _facing_direction, FacingDirection.size())
		_: #assumes up or down refers to "FRONT"
			return min(
				posmod(FacingDirection.FRONT_CLOCKWISE - _facing_direction, FacingDirection.size()),
				posmod(FacingDirection.FRONT_COUNTERCLOCKWISE - _facing_direction, FacingDirection.size())
			)

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
