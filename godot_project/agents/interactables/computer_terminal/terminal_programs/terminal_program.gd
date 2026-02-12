extends Node

class_name TerminalProgram

##If this terminal program can be controlled by the sequencer, this scene will be sent to the sequencer screen
@export var sequencer_control_scene: PackedScene

## Override in child classes
func run():
	pass

func reset():
	pass
