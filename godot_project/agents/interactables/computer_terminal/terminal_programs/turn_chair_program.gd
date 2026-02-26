extends TerminalProgram

class_name TurnChairProgram

@export var chairs : Array[SpinningChair]
@export var number_of_quarter_turns := 2

var _previously_selected_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://crorf1owblj5p"
	super._ready()

func run():
	for chair in chairs:
		chair.spin(number_of_quarter_turns)

func reset():
	pass

func initialize_screen(screen_scene: TurnChairScreen):
	super.initialize_screen(screen_scene)
	if screen_scene is not TurnChairScreen:
		push_error("Ensure that change_laser_direction_program has change_laser_direction_screen ans its
		sequencer control scene")
	screen_scene.direction_pressed.connect(_on_direction_selected)

func _on_direction_selected(direction: Enums.Direction):
	for chair in chairs:
		if direction == _previously_selected_direction:
			break
		elif direction == Enums.Direction.LEFT and chair._facing_direction == chair.FacingDirection.FRONT_COUNTERCLOCKWISE:
			chair.start_direction = chair.FacingDirection.FRONT_CLOCKWISE
		elif direction == Enums.Direction.RIGHT and chair._facing_direction == chair.FacingDirection.FRONT_CLOCKWISE:
			chair.start_direction = chair.FacingDirection.FRONT_COUNTERCLOCKWISE
		chair.spin(chair.get_quarter_turns_to_direction(direction))
	_previously_selected_direction = direction

func _determine_quarter_spins(direction: Enums.Direction):
	pass
	#if direction == Enums.Direction.DOWN and _previously_selected_direction != Enums.Direction.DOWN
