extends Node

class_name TerminalProgram

var sequencer_control_scene_UID : String

##If this terminal program can be controlled by the sequencer, this scene will be sent to the sequencer screen
var sequencer_control_scene: PackedScene

func _ready() -> void:
	if sequencer_control_scene_UID:
		sequencer_control_scene = load(sequencer_control_scene_UID)
	elif get_parent() is Antenna:
		push_error("Antenna Terminal program is missing UID for sequencer control screen scene. The variable
		 sequencer_control_scene must be set in _ready() for any terminal program attached to an antenna")

##Terminal programs can override this function to connect to signals from the sequencer screen. Sequencer is responsible
##for unpacking and initializing the screen, so it passes a reference to it here.
func initialize_screen(screen_scene):
	pass

## Override in child classes
func run():
	pass

func reset():
	pass
