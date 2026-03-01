extends TerminalProgram

class_name ChangeLaserHeightProgram

@export var lasers : Array[Laser]
@export var new_height : int
@export var animation_speed := 0.4

var original_heights: Array[int]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene = load("uid://d8l1lrlubiip")
	super._ready()
	for laser in lasers:
		original_heights.append(laser.height)

func initialize_screen(screen_scene: ChangeLaserHeightScreen):
	super.initialize_screen(screen_scene)
	if screen_scene is not ChangeLaserHeightScreen:
		push_error("Ensure that change_treadmill_direction_program has change_laser_direction_screen and its
		sequencer control scene")
	screen_scene.value_updated.connect(_on_height_updated)

func _on_height_updated(new_height: int):
	for laser in lasers:
		laser.height = new_height

func run():
	for laser in lasers:
		laser.set_height_animated(new_height, animation_speed)

func reset():
	for i in range(lasers.size()):
		lasers[i].height = original_heights[i]
