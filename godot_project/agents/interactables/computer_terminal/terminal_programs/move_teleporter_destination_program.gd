extends TerminalProgram

class_name MoveTeleporterDestinationProgram

@export var teleporter : Teleporter

@onready var _teleporting := false

var digipad : DigipadCycle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://c3oui8nrbnmi4"
	#for convenience, just set teleporter to whatever owns this antenna program
	if not teleporter:
		var gramps = get_parent().get_parent()
		if gramps is Teleporter:
			teleporter = gramps
	if not teleporter:
		push_error("No teleporter sselected for move teleporter destination program")
	teleporter.began_teleport.connect(_on_teleport_begin)
	teleporter.completed_teleport.connect(_on_teleport_complete)
	super._ready()

func initialize_screen(screen_scene: MoveTeleporterDestinationScreen):
	super.initialize_screen(screen_scene)
	digipad = screen_scene.digipad
	digipad.option_cycled.connect(_on_option_cycled)
	digipad.number_of_options = teleporter.destination_targets.size()

func run() -> void:
	if teleporter.destination_targets.size() > 0:
		teleporter.destination = teleporter.destination_targets[1].grid_position

func _on_option_cycled(index: int):
	var new_index = index
	#don't update destination target until teleportation complete
	if _teleporting:
		if digipad:
			digipad.option_cycled.disconnect(_on_option_cycled)
		await teleporter.completed_teleport
		new_index = digipad.index
		if digipad:
			digipad.option_cycled.connect(_on_option_cycled)
	teleporter.destination = teleporter.destination_targets[new_index].grid_position

func _on_teleport_begin(_entity):
	_teleporting = true

func _on_teleport_complete():
	_teleporting = false

func reset():
	super.reset()
	_teleporting = false
