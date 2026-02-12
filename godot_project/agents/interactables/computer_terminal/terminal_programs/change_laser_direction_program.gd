extends TerminalProgram

class_name TurnLaserProgram

@export var lasers : Array[Laser]
@export var new_direction : Enums.Direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func run():
	print("turning laser to direction")

func reset():
	pass
