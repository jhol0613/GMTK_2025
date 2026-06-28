extends TerminalProgram

class_name TurnTreadmillProgram

@export var treadmills : Array[Treadmill]
@export var new_direction : Enums.Direction
##Number of times treadmill can be rotated 90 deg counterclockwise from starting position
@export var left_limit: int = -99999
##Number of times treadmill can be rotated 90 deg clockwise from starting position
@export var right_limit: int = 99999

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	antenna_group = treadmills
	sequencer_control_scene_UID = Enums.SequencerControlScene.TURN_TREADMILL
	super._ready()

func initialize_screen(screen_scene: ChangeTreadmillDirectionScreenV2):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)
	if treadmills.is_empty():
		return
	var limit_offset = _get_limit_offset(treadmills[0].original_direction, treadmills[0].direction)
	screen_scene.set_limits(left_limit + limit_offset, right_limit + limit_offset)

##Returns number of quarter turns required to get to the current direction from the original
func _get_limit_offset(original_direction: Enums.Direction, current_direction: Enums.Direction) -> int:
	var i := -2
	var dir := Enums.rotate_90_left(Enums.rotate_90_left(current_direction))
	while dir != original_direction and i < 2:
		i += 1
		dir = Enums.rotate_90_right(dir)
	return i

func _on_direction_selected(direction: Enums.Direction):
	for treadmill in treadmills:
		if should_reset_position == PositionResetMode.AUTO or should_reset_position == PositionResetMode.FALSE:
			treadmill.original_direction = treadmill.direction
		if direction == Enums.Direction.LEFT:
			treadmill.direction = Enums.rotate_90_left(treadmill.direction)
		elif direction == Enums.Direction.RIGHT:
			treadmill.direction = Enums.rotate_90_right(treadmill.direction)

func run():
	for treadmill in treadmills:
		treadmill.direction = new_direction
		if should_reset_position == PositionResetMode.TRUE:
			treadmill.original_direction = new_direction

func reset():
	for treadmill in treadmills:#original_directions.keys():
		treadmill.direction = treadmill.original_direction
	if current_sequencer_control_scene is ChangeTreadmillDirectionScreenV2:
		var limit_offset = _get_limit_offset(treadmills[0].original_direction, treadmills[0].direction)
		current_sequencer_control_scene.set_limits(left_limit + limit_offset, right_limit + limit_offset)
		current_sequencer_control_scene.reset()
	super.reset()
