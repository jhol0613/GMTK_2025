extends TerminalProgram

class_name TurnTreadmillProgram

@export var treadmills : Array[Treadmill]
@export var new_direction : Enums.Direction
@export var allowed_directions : Array[Enums.Direction] = [
	Enums.Direction.UP,
	Enums.Direction.DOWN,
	Enums.Direction.LEFT,
	Enums.Direction.RIGHT]

var original_directions : Dictionary[Treadmill, Enums.Direction]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://c0rrg37ad7473"
	for treadmill in treadmills:
		original_directions[treadmill] = treadmill.direction
	super._ready()

func initialize_screen(screen_scene: ChangeTreadmillDirectionScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)
	screen_scene.set_allowed_directions(allowed_directions)
	if treadmills.size() > 0:
		current_sequencer_control_scene.set_direction(treadmills[0].direction)

func _on_direction_selected(direction: Enums.Direction):
	#TODO: Update original direction depending on position reset mode
	for treadmill in treadmills:
		treadmill.direction = direction
		if should_reset_position == PositionResetMode.AUTO or PositionResetMode.FALSE:
			treadmill.original_direction = direction

func run():
	for treadmill in treadmills:
		treadmill.direction = new_direction
		if should_reset_position == PositionResetMode.TRUE:
			treadmill.original_direction = new_direction

func reset():
	for treadmill in original_directions.keys():
		treadmill.direction = original_directions[treadmill]
	if current_sequencer_control_scene is ChangeTreadmillDirectionScreen and treadmills.size() > 0:
		current_sequencer_control_scene.set_direction(treadmills[0].direction)
	super.reset()
