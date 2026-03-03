extends TerminalProgram

class_name MoveTeleporterDestinationProgram

@export var teleporters : Array[Teleporter]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene = load("uid://c3oui8nrbnmi4")
	super._ready()

func initialize_screen(screen_scene: MoveTeleporterDestinationScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)

func _run() -> void:
	pass

func _on_direction_selected(direction: Enums.Direction):
	for teleporter in teleporters:
		teleporter.destination += Enums.direction_to_vector(direction)
