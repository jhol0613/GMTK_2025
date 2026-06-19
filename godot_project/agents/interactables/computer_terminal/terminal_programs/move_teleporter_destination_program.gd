extends TerminalProgram

class_name MoveTeleporterDestinationProgram

@export var teleporters : Array[Teleporter]

@onready var _entities_teleporting := 0

var digipad : DigipadCycle

signal _all_entities_done_teleporting

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = Enums.SequencerControlScene.MOVE_TELEPORT_DESTINATION
	#for convenience, just set teleporter to whatever owns this antenna program
	if teleporters.size() == 0:
		var gramps = get_parent().get_parent()
		if gramps is Teleporter:
			teleporters.append(gramps)
	if teleporters.size() == 0:
		push_error("No teleporter sselected for move teleporter destination program")
	var num_destinations = teleporters[0].destination_targets.size()
	for teleporter in teleporters:
		if teleporter.destination_targets.size() != num_destinations:
			push_error("If one antenna program controls multiple teleporters, they must have the same number of destinations")
		teleporter.began_teleport.connect(_on_teleport_begin)
		teleporter.completed_teleport.connect(_on_teleport_complete)
	super._ready()

func initialize_screen(screen_scene: MoveTeleporterDestinationScreen):
	super.initialize_screen(screen_scene)
	digipad = screen_scene.digipad
	digipad.option_cycled.connect(_on_option_cycled)
	digipad.number_of_options = teleporters[0].destination_targets.size()

func run() -> void:
	for teleporter in teleporters:
		if teleporter.destination_targets.size() > 0:
			teleporter.current_destination_target = teleporter.destination_targets[1]
			#teleporter.destination = teleporter.destination_targets[1].grid_position

func _on_option_cycled(index: int):
	var new_index = index
	#don't update destination target until teleportation complete
	if _entities_teleporting > 0:
		if digipad:
			digipad.option_cycled.disconnect(_on_option_cycled)
		await _all_entities_done_teleporting
		new_index = digipad.index
		if digipad:
			digipad.option_cycled.connect(_on_option_cycled)
	for teleporter in teleporters:
		teleporter.current_destination_target = teleporter.destination_targets[new_index]
		#teleporter.destination = teleporter.destination_targets[new_index].grid_position

func _on_teleport_begin(_entity):
	_entities_teleporting += 1

func _on_teleport_complete():
	_entities_teleporting -= 1
	if _entities_teleporting == 0:
		_all_entities_done_teleporting.emit()

func reset():
	super.reset()
	_entities_teleporting = 0
