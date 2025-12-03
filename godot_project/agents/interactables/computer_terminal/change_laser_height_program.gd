extends TerminalProgram

class_name ChangeLaserHeightProgram

@export var lasers : Array[Laser]
@export var new_height : int
@export var animation_speed := 0.4

var original_heights: Array[int]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for laser in lasers:
		original_heights.append(laser.height)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func run():
	for laser in lasers:
		laser.set_height_animated(new_height, animation_speed)

func reset():
	for i in range(lasers.size()):
		lasers[i].height = original_heights[i]
