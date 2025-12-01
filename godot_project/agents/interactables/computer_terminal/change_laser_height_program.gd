extends TerminalProgram

class_name ChangeLaserHeightProgram

@export var lasers : Array[Laser]
@export var new_height : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func run():
	for laser in lasers:
		laser.height = new_height
