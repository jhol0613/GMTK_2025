extends Movable

class_name MovableObstacle

##Repeating path for this object to follow
@export var movement_path: Array[Enums.PlayerAction]
@export var pusher: Pusher
##Push action doesn't update until first movement, so set this if initial push action required
@export var initial_push_action := Enums.PlayerAction.DOWN_FALL
##A disabled obstacle will not move or use its pusher, and its grid space will be considered unoccupied
@export var enabled := true: set = _set_enabled
@export var reset_on_play_pressed := true
##If true, push action will not automatically update when move cursor is advanced
@export var manually_update_push_action := false

@onready var _move_cursor_start_position := 0
@onready var _move_cursor := _move_cursor_start_position

# Not used by base class, but can be used by children
signal request_offbeat_action(obstacle: MovableObstacle, action: Enums.PlayerAction, update_origin: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("movable_obstacles")
	if pusher:
		pusher.push_action = initial_push_action
	super._ready()

##override _execute_action from movable so behavior can be altered if pusher would have caused a player fall
##This is modified to not calculate a move delay, since obstacle movements are synched by level manager.
##Typically, the level manager calls execute action on beat 0, and individual movables handle the timing.
##Since obstacle movements require synching logic in the level manager, the level manager uses their default
##action beat and fires execute action on the appropriate beat, so any additional delay is unwarranted. Thus
##instant defaults to true. It also means you can't currently have sounds that trigger prior to the beat
func execute_action(action: Enums.PlayerAction, beat: int, skip_animation := false, instant = true):
	if not enabled:
		return
	# if action is a fall action, rather than using the pusher action, just go back the way you came
	if Enums.is_action_fall(action):
		super.execute_action(Enums.get_reverse_action(movement_path[_move_cursor-1]), beat, skip_animation, instant)
		#play bump sound on collision with another movable obstacle
		interrupt_queued_sound()
		var emitter = action_sound_emitters.get(Enums.PlayerAction.LEFT_BONK, default_sound_emitter)
		if emitter:
			emitter.play()
	else:
		super.execute_action(action, beat, skip_animation, instant)
		if Enums.is_action_slide(action):
			pusher.push_action = _direction_to_push_action(action)

func get_next_move() -> Enums.PlayerAction:
	if movement_path.size() == 0:
		return Enums.PlayerAction.NONE
	return movement_path[_move_cursor]

## Move to next action in the sequence (for example, call this after a move or a bonk but not after a slide)
func advance_move_cursor():
	_move_cursor += 1
	if _move_cursor >= movement_path.size():
		_move_cursor = 0
	if pusher and movement_path.size() > 0 and not manually_update_push_action:
		pusher.push_action = _direction_to_push_action(movement_path[(_move_cursor-1) % movement_path.size()])

##Push action is what happens to a movable that overlaps the obstacle. If not up/left/right/down, just
##return the same push action that's currently set
func _direction_to_push_action(move_direction: Enums.PlayerAction) -> Enums.PlayerAction:
	match move_direction:
		Enums.PlayerAction.UP, Enums.PlayerAction.UP_SLIDE:
			return Enums.PlayerAction.UP_FALL
		Enums.PlayerAction.DOWN, Enums.PlayerAction.DOWN_SLIDE:
			return Enums.PlayerAction.DOWN_FALL
		Enums.PlayerAction.LEFT, Enums.PlayerAction.LEFT_SLIDE:
			return Enums.PlayerAction.LEFT_FALL
		Enums.PlayerAction.RIGHT, Enums.PlayerAction.RIGHT_SLIDE:
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
	request_offbeat_action.emit(self, Enums.PlayerAction.NONE, false)
	_move_cursor = _move_cursor_start_position
