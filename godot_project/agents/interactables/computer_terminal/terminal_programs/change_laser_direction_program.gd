extends TerminalProgram

class_name TurnLaserProgram

@export var lasers : Array[Laser]
@export var new_direction : Enums.Direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://dw1sgggrlnrke"
	super._ready()

func initialize_screen(screen_scene: ChangeLaserDirectionScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)

func _on_direction_selected(direction: Enums.Direction):
	for laser in lasers:
		laser.direction = direction

func run():
	for laser in lasers:
		laser.direction = new_direction

func reset():
	pass
