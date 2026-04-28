extends Node

class_name TerminalProgram

##Default is auto, where obstacle will reset position if it was moved via terminal or maintain its position
##if moved via antenna.
@export var should_reset_position := PositionResetMode.AUTO

var sequencer_control_scene_UID : String

##If this terminal program can be controlled by the sequencer, this scene will be sent to the sequencer screen
var packed_sequencer_control_scene: PackedScene

var current_sequencer_control_scene

enum PositionResetMode {
	AUTO,
	TRUE,
	FALSE
}

func _ready() -> void:
	if sequencer_control_scene_UID:
		packed_sequencer_control_scene = load(sequencer_control_scene_UID)
	elif get_parent() is Antenna:
		push_error("Antenna Terminal program is missing UID for sequencer control screen scene. The variable
		 packed_sequencer_control_scene must be set in _ready() for any terminal program attached to an antenna")

##Terminal programs can override this function to connect to signals from the sequencer screen. Sequencer is responsible
##for unpacking and initializing the screen, so it passes a reference to it here.
func initialize_screen(screen_scene):
	current_sequencer_control_scene = screen_scene

## Override in child classes
func run():
	pass

func reset():
	pass
