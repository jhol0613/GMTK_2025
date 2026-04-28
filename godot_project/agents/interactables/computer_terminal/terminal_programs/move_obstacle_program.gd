extends TerminalProgram

class_name MoveObstacleProgram

@export var obstacles : Array[MovableObstacle]
##Should match indices of the obstacles they apply to
@export var obstacle_limiters : Array[MovableObstacleLimiter]
##Action to take when program is run
@export var action := Enums.PlayerAction.LEFT

@onready var _use_limiters = obstacles.size() == obstacle_limiters.size() and not obstacle_limiters.is_empty()

##flag for allowing antenna program position changes to be persistent across resets
var should_update_origin = false 

var _number_of_movement_complete = 0
var _cooldown_in_progress = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequencer_control_scene_UID = "uid://cwm6kjroqw6hn"
	super._ready()
	if should_reset_position == PositionResetMode.FALSE:
		should_update_origin = true
	if obstacles.size() != obstacle_limiters.size():
		push_error("Obstacle Limiters array must be the same size as Obstacles array")

func initialize_screen(screen_scene: MoveCartScreen):
	super.initialize_screen(screen_scene)
	if _use_limiters:
		_update_allowed_actions(Enums.Direction.UP, Vector2i(0,0))
	screen_scene.direction_pressed.connect(_on_direction_selected)

func run() -> void:
	_cooldown_in_progress = true
	
	if _use_limiters:
		_run_with_limiters()
	else:
		_run_without_limiters()
	if should_reset_position == PositionResetMode.AUTO:
		should_update_origin = false

func _run_without_limiters():
	for obstacle in obstacles:
		obstacle.request_offbeat_action.emit(obstacle, action, should_update_origin)
		obstacle.movement_complete.connect(_on_obstacle_movement_complete)

func _run_with_limiters():
	for i in range(obstacles.size()):
		if not obstacle_limiters[i]:
			continue
		if obstacle_limiters[i].is_direction_allowed(obstacles[i].global_position, 
			Enums.player_action_to_direction(action), obstacles[i].tile_size):
			obstacles[i].request_offbeat_action.emit(obstacles[i], action, should_update_origin)
			obstacles[i].movement_complete.connect(_on_obstacle_movement_complete)
		else:
			_on_obstacle_movement_complete(obstacles[i]) #call this for obstacles that didn't move due to limiter check,otherwise cooldown will never get reset

func _on_obstacle_movement_complete(obstacle: MovableObstacle):
	_number_of_movement_complete += 1
	if obstacle.movement_complete.is_connected(_on_obstacle_movement_complete):
		obstacle.movement_complete.disconnect(_on_obstacle_movement_complete)
	if _number_of_movement_complete >= obstacles.size():
		_number_of_movement_complete = 0
		_cooldown_in_progress = false

func _on_direction_selected(direction: Enums.Direction):
	if _cooldown_in_progress:
		return
	if should_reset_position == PositionResetMode.AUTO:
		should_update_origin = true
	action = Enums.direction_to_action(direction)
	for obstacle in obstacles:
		obstacle.pusher.push_action = Enums.direction_to_fall_action(direction)
	if _use_limiters:
		_update_allowed_actions(direction)
	run()

##update move obstacle screen to make actions outside of moving obstacle limits.
##Note that when this update is called, the cart won't have moved yet. So you have to apply the action that it's about to execute
##and then check that position for what's allowed by obstacle limits. To disregard queued move, set move direction multiplier to 0
func _update_allowed_actions(queued_move_direction: Enums.Direction, move_direction_multiplier := Vector2i(1, 1)):
	var allowed_directions : Dictionary[Enums.Direction, bool] = {
		Enums.Direction.UP: false,
		Enums.Direction.DOWN: false,
		Enums.Direction.LEFT: false,
		Enums.Direction.RIGHT: false
	}

	for i in range(obstacles.size()):
		if not obstacle_limiters[i]:
			continue
		var position_after_current_move = obstacles[i].global_position + \
			Vector2(Enums.direction_to_vector(queued_move_direction) * obstacles[i].tile_size * \
			move_direction_multiplier)
		var directions_allowed_by_this_limiter = obstacle_limiters[i].get_allowed_directions(
			position_after_current_move, obstacles[i].tile_size
		)
		for key in allowed_directions.keys():
			allowed_directions[key] = allowed_directions[key] or directions_allowed_by_this_limiter[key]
	if current_sequencer_control_scene is MoveCartScreen:
		current_sequencer_control_scene.set_allowed_directions(allowed_directions)
