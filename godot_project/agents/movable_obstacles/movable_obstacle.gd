extends Movable

class_name MovableObstacle

##Repeating path for this object to follow
@export var movement_path: Array[Enums.PlayerAction]
##Delay after sequencer fires before grid is updated
@export var update_delay: float
@export var pusher: Pusher

@onready var _move_cursor_start_position := 0
@onready var _move_cursor := _move_cursor_start_position
@onready var _queued_push_action: Enums.PlayerAction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	add_to_group("movable_obstacles")
	#tick.connect(_on_tick)

## This has a side effect of advancing the move cursor each time it is called
func get_next_move() -> Enums.PlayerAction:
	if movement_path.size() == 0:
		return Enums.PlayerAction.NONE
	var move_to_return = movement_path[_move_cursor]
	pusher.push_action = _direction_to_push_action(movement_path[_move_cursor])
	_move_cursor += 1
	if _move_cursor >= movement_path.size():
		_move_cursor = 0
	return move_to_return

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

func reset():
	super.reset()
	_move_cursor = _move_cursor_start_position
