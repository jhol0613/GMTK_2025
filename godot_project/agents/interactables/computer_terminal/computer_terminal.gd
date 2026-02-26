@tool

extends Interactable

class_name Terminal

##Number of beats before action occurs after player starts terminal interaction, since it would take time to type and execute
@export var input_delay_beats := 2.0
var programs : Array[TerminalProgram]

signal selected(programs: Array[TerminalProgram])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	add_to_group("terminals")
	interaction_succeeded.connect(_on_successful_interaction)
	if repeatable:
		follow_on_animations[Enums.PlayerAction.INTERACT] = "idle"
	for child in get_children():
		if child is TerminalProgram:
			programs.append(child)

# Ensure terminal program is configured as a child node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	for child in get_children():
		if child is TerminalProgram:
			return warnings
	warnings.append("Terminal must have at least one terminal program as a direct child in order to have any functionality")
	return warnings
	
func _on_successful_interaction():
	print(AudioManager.beat_time_seconds)
	await get_tree().create_timer(AudioManager.beat_time_seconds * input_delay_beats).timeout
	for program in programs:
		program.run()

func reset():
	super.reset()
	for child in get_children():
		if child is TerminalProgram:
			child.reset()
	
