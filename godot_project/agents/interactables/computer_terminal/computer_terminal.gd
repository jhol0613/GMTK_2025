@tool

extends Interactable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	interaction_succeeded.connect(_on_successful_interaction)
	
# Ensure terminal program is configured as a child node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	for child in get_children():
		if child is TerminalProgram:
			return warnings
	warnings.append("Terminal must have at least one terminal program as a direct child in order to have any functionality")
	return warnings
	
func _on_successful_interaction():
	for child in get_children():
		if child is TerminalProgram:
			child.run()

func reset():
	super.reset()
	for child in get_children():
		if child is TerminalProgram:
			child.reset()
	
