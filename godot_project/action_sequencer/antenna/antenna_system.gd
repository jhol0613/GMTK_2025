extends Node2D

class_name AntennaSystem

var programs : Array[TerminalProgram]
var antennas : Array[AntennaComponent]

signal selected(programs: Antenna)

func _ready() -> void:
	add_to_group("antenna_systems")
	for child in get_children():
		if child is TerminalProgram:
			programs.append(child)
	for program: TerminalProgram in programs:
		for object in program.antenna_group:
			for child in object.find_children("*", "", true):
				if child is AntennaComponent:
					antennas.append(child)
	for antenna in antennas:
		antenna.mouse_entered.connect(_on_mouse_entered)
		antenna.mouse_exited.connect(_on_mouse_exited)
		antenna.selected.connect(_on_antenna_selected)
		antenna.activate()

func _on_mouse_entered():
	for antenna in antennas:
		antenna.highlight()

func _on_mouse_exited():
	for antenna in antennas:
		antenna.unhighlight()

func _on_antenna_selected(selected_antenna_position: Vector2):
	selected.emit(self, selected_antenna_position)

func set_active_animation(new_active):
	for antenna in antennas:
		antenna.set_broadcasting(new_active)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	for child in get_children():
		if child is TerminalProgram:
			return warnings
	warnings.append("Antenna must have at least one terminal program as a direct child in order to have any functionality")
	return warnings
