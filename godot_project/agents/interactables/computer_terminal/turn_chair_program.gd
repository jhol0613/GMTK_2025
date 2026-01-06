extends TerminalProgram

class_name TurnChairProgram

@export var chairs : Array[SpinningChair]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func run():
	for chair in chairs:
		chair.spin()

func reset():
	pass
