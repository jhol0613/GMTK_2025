extends TerminalProgram

class_name TurnChairProgram

@export var chairs : Array[SpinningChair]
@export var number_of_quarter_turns := 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func run():
	for chair in chairs:
		chair.spin(number_of_quarter_turns)

func reset():
	pass
