extends TerminalProgram

class_name MoveObstacleProgram

@export var obstacles : Array[MovableObstacle]
##Action to take when program is run
@export var action := Enums.PlayerAction.LEFT

##flag for allowing antenna program position changes to be persistent across resets
var should_update_origin = false 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://cwm6kjroqw6hn"
	super._ready()

func initialize_screen(screen_scene: MoveCartScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)

func run() -> void:
	for obstacle in obstacles:
		obstacle.request_offbeat_action.emit(obstacle, action, should_update_origin)
	should_update_origin = false

func _on_direction_selected(direction: Enums.Direction):
	should_update_origin = true
	action = Enums.direction_to_action(direction)
	run()
