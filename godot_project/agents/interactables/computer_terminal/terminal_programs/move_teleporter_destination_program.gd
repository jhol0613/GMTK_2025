extends TerminalProgram

class_name MoveTeleporterDestinationProgram

@export var teleporter : Teleporter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://c3oui8nrbnmi4"
	#for convenience, just set teleporter to whatever owns this antenna program
	if not teleporter:
		var gramps = get_parent().get_parent()
		if gramps is Teleporter:
			teleporter = gramps
	super._ready()

func initialize_screen(screen_scene: MoveTeleporterDestinationScreen):
	super.initialize_screen(screen_scene)
	screen_scene.digipad.option_cycled.connect(_on_option_cycled)
	screen_scene.digipad.number_of_options = teleporter.destination_targets.size()

func _run() -> void:
	pass

func _on_option_cycled(index: int):
	teleporter.destination = teleporter.destination_targets[index].grid_position
