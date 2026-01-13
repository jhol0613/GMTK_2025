extends Movable

class_name MovableObstacle

##Repeating path for this object to follow
@export var movement_path: Array[Enums.PlayerAction]
@export var pusher: Pusher
##A disabled obstacle will not move or use its pusher, and its grid space will be considered unoccupied
@export var enabled := true: set = _set_enabled

@onready var _move_cursor_start_position := 0
@onready var _move_cursor := _move_cursor_start_position

# Not used by base class, but can be used by children
signal request_offbeat_action(obstacle: MovableObstacle, action: Enums.PlayerAction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("movable_obstacles")
	super._ready()

# override _execute_action from movable so behavior can be altered if pusher would have caused a player fall
func execute_action(action: Enums.PlayerAction, beat: int, skip_animation := false):
	if not enabled:
		return
	# if action is a fall action, rather than using the pusher action, just go back the way you came
	if Enums.is_action_fall(action):
		super.execute_action(Enums.get_reverse_action(movement_path[_move_cursor-1]), skip_animation)
	else:
		super.execute_action(action, beat, skip_animation)

func get_next_move() -> Enums.PlayerAction:
	if movement_path.size() == 0:
		return Enums.PlayerAction.NONE
	return movement_path[_move_cursor]

## Move to next action in the sequence (for example, call this after a move or a bonk but not after a slide)
func advance_move_cursor():
	_move_cursor += 1
	if _move_cursor >= movement_path.size():
		_move_cursor = 0
	if pusher and movement_path.size() > 0: 
		pusher.push_action = _direction_to_push_action(movement_path[(_move_cursor-1) % movement_path.size()])

##Push action is what happens to a movable that overlaps the obstacle. If not up/left/right/down, just
##return the same push action that's currently set
func _direction_to_push_action(move_direction: Enums.PlayerAction) -> Enums.PlayerAction:
	match move_direction:
		Enums.PlayerAction.UP:
			return Enums.PlayerAction.UP_FALL
		Enums.PlayerAction.DOWN:
			return Enums.PlayerAction.DOWN_FALL
		Enums.PlayerAction.LEFT:
			return Enums.PlayerAction.LEFT_FALL
		Enums.PlayerAction.RIGHT:
			return Enums.PlayerAction.RIGHT_FALL
	return pusher.push_action

##Sets the position in the move sequence where the cursor should start
func set_move_cursor_start_position(new_start_position: int):
	_move_cursor_start_position = new_start_position

func _set_enabled(new_enabled):
	pusher._set_enabled(new_enabled)
	enabled = new_enabled

func reset():
	super.reset()
	_move_cursor = _move_cursor_start_position
