extends TerminalProgram

class_name TurnLaserProgram

@export var lasers : Array[Laser]
@export var new_direction : Enums.Direction
@export var allowed_directions : Array[Enums.Direction] = [
	Enums.Direction.UP,
	Enums.Direction.DOWN,
	Enums.Direction.LEFT,
	Enums.Direction.RIGHT]

var original_directions : Dictionary[Laser, Enums.Direction]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://dw1sgggrlnrke"
	for laser in lasers:
		original_directions[laser] = laser.direction
	super._ready()

func initialize_screen(screen_scene: ChangeLaserDirectionScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)
	screen_scene.set_allowed_directions(allowed_directions)
	if lasers.size() > 0:
		screen_scene.set_direction(lasers[0].direction)

func _on_direction_selected(direction: Enums.Direction):
	for laser in lasers:
		laser.direction = direction

func run():
	for laser in lasers:
		laser.direction = new_direction

func reset():
	for laser in lasers:
		laser.direction = original_directions[laser]
	if lasers.size() > 0 and current_sequencer_control_scene is ChangeLaserDirectionScreen:
		current_sequencer_control_scene.set_direction(lasers[0].direction)
