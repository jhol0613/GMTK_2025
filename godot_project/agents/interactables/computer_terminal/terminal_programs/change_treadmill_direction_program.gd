extends TerminalProgram

class_name TurnTreadmillProgram

@export var treadmills : Array[Treadmill]
@export var new_direction : Enums.Direction

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

func _on_direction_selected(direction: Enums.Direction):
	for treadmill in treadmills:
		treadmill.direction = direction

func run():
	for treadmill in treadmills:
		treadmill.direction = new_direction

func reset():
	for treadmill in treadmills:
		treadmill.direction = original_directions[treadmill]
