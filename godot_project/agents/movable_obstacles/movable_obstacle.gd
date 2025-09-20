extends Movable

class_name MovableObstacle

##Repeating path for this object to follow
@export var movement_path: Array[Enums.PlayerAction]
##Delay after sequencer fires before grid is updated
@export var update_delay: float
@export var pusher: Pusher

@onready var _move_cursor := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#tick.connect(_on_tick)

## This has a side effect of advancing the move cursor each time it is called
func get_next_move():
	if movement_path.size() == 0:
		return Enums.PlayerAction.NONE
	var move_to_return = movement_path[_move_cursor]
	_move_cursor += 1
	if _move_cursor >= movement_path.size():
		_move_cursor = 0
	pusher.push_action = movement_path[_move_cursor]
	return movement_path[_move_cursor]

func _on_tick(beat: int) -> void:
	pass

func _on_action_executed(action: Enums.PlayerAction) -> void:
	pass
	
func reset():
	super.reset()
	_move_cursor = 0
