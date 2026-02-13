extends TerminalProgram

class_name TurnLaserProgram

@export var lasers : Array[Laser]
@export var new_direction : Enums.Direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func run():
	for laser in lasers:
		laser.direction = new_direction

func reset():
	pass
