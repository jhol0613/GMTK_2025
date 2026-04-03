extends TerminalProgram

class_name MoveObstacleProgram

@export var obstacles : Array[MovableObstacle]
##Action to take when program is run
@export var action := Enums.PlayerAction.LEFT
##Default is auto, where obstacle will reset position if it was moved via terminal or maintain its position
##if moved via antenna.
@export var should_reset_position := PositionResetMode.AUTO

enum PositionResetMode {
	AUTO,
	TRUE,
	FALSE
}

##flag for allowing antenna program position changes to be persistent across resets
var should_update_origin = false 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://cwm6kjroqw6hn"
	super._ready()
	if should_reset_position == PositionResetMode.FALSE:
		should_update_origin = true

func initialize_screen(screen_scene: MoveCartScreen):
	super.initialize_screen(screen_scene)
	screen_scene.direction_pressed.connect(_on_direction_selected)

func run() -> void:
	for obstacle in obstacles:
		obstacle.request_offbeat_action.emit(obstacle, action, should_update_origin)
	if should_reset_position == PositionResetMode.AUTO:
		should_update_origin = false

func _on_direction_selected(direction: Enums.Direction):
	if should_reset_position == PositionResetMode.AUTO:
		should_update_origin = true
	action = Enums.direction_to_action(direction)
	run()
