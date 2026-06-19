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
	screen_scene.set_limits(left_limit, right_limit)

func _on_direction_selected(direction: Enums.Direction):
	for treadmill in treadmills:
		if should_reset_position == PositionResetMode.AUTO or PositionResetMode.FALSE:
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
		treadmill.direction = treadmill.original_direction #original_directions[treadmill]
	#if current_sequencer_control_scene is ChangeTreadmillDirectionScreen and treadmills.size() > 0:
		#current_sequencer_control_scene.set_direction(treadmills[0].direction)
	if current_sequencer_control_scene is ChangeTreadmillDirectionScreenV2:
		current_sequencer_control_scene.reset()
	super.reset()
