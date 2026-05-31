extends TerminalProgram

class_name TurnChairProgram

@export var chairs : Array[SpinningChairV2]
@export var number_of_quarter_turns := 2
@export var rotation_left_limit = -99999999
@export var rotation_right_limit = 99999999

var _previously_selected_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://crorf1owblj5p"
	super._ready()

func run():
	for chair in chairs:
		chair.spin(number_of_quarter_turns)

func reset():
	for chair in chairs:
		if _previously_selected_direction:
			chair.start_direction = _previously_selected_direction
			chair.reset()
	if current_sequencer_control_scene is TurnChairScreen:
		current_sequencer_control_scene.reset()
	#if chairs.size() > 0 and current_sequencer_control_scene is TurnChairScreen:
		#current_sequencer_control_scene.set_direction(chairs[0].get_direction())
	super.reset()

func initialize_screen(screen_scene: TurnChairScreen):
	super.initialize_screen(screen_scene)
	if screen_scene is not TurnChairScreen:
		push_error("Ensure that change_laser_direction_program has change_laser_direction_screen ans its
		sequencer control scene")
	screen_scene.direction_pressed.connect(_on_direction_selected)
	screen_scene.set_limits(rotation_left_limit, rotation_right_limit)
	#if chairs[0]:
		#screen_scene.set_direction(chairs[0].get_direction())

func _on_direction_selected(direction: Enums.Direction):
	var should_update_origin = should_reset_position == PositionResetMode.AUTO or should_reset_position == PositionResetMode.TRUE
	for chair in chairs:
		chair.spin(-1 if direction == Enums.Direction.LEFT else 1, should_update_origin)
	if should_update_origin:
		for chair in chairs:
			await chair._frame_timer.timeout
			chair.start_direction = chair._facing_direction

	#_previously_selected_direction = direction
