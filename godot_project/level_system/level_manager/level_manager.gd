extends Node2D

#region Export Variables
@export_category("Scenes")
@export_subgroup("Player", "player")
@export var player_scene: PackedScene

@export_subgroup("Conductor", "conductor")
@export var conductor_scene: PackedScene

@export_category("Animation")
@export_subgroup("Train Car Positioning")
##The initial position of a train car in the level
@export var initial_train_position := Vector2(132, 188)
##The distance in pixels to space out train cars
@export var next_car_offset := 490
##The distance that a train car will move (right) when play is pressed
@export var train_move_right_on_play_distance := -22
##The amount of time it takes for train car to offset on pressing play
@export var train_move_right_on_play_time := 1.0
##The amount of time required for the level to visually advance
@export var train_car_advance_play_time := 2.5
@export_subgroup("Reset Delays")
## How long to wait before scrolling to the next level (e.g. to allow time for animation)
@export var level_success_delay := 2.0
## How long to wait to reset the level after a failure
@export var level_failure_delay := 2.0
##Amount of time to wait before beginning world transition
@export var world_transition_begin_delay := 5.0
@export_subgroup("Thinking Mode Filter")
@export_range(0, 1, .01) var brightness: float
@export_range(0, 1, .01) var contrast: float
@export_range(0, 1, .01) var saturation: float
@export var filter_animation_time := 1.5
@export_subgroup("Antenna Lightning")
@export var lightning_duration := 0.2
@export var lightning_screen_shake_decay := 10.0
@export var lightning_sreen_shake_strength := 8.0

@export_category("Levels")
## All train cars in order
#@export var level_list: Array[PackedScene]
@export var level_catalog: LevelCatalog
#endregion

#region Level Manager Initialization
@onready var _level_scene : RhythmRailLevel
@onready var _world_scene : Node = GameManager.level_catalog.get_world_scene().instantiate()
@onready var _action_sequencer : ActionSequencer = $SequencerLayer/ActionSequencer
@onready var _on_the_train : = $TrainCenter/OnTheTrain
# needs to exist since you can't animate x and y values for on the train separately, don't want train rock
# animation to reset train horizontal position
@onready var _train_center: = $TrainCenter
@onready var _animation_player := $AnimationPlayer
@onready var _shader := $ShaderLayer/Shader
@onready var _shake_camera := $ShakeCamera
@onready var _lightning := $SequencerLayer/Lightning


var _conductor: Conductor
var _player_character: PlayerCharacter

var _next_level: RhythmRailLevel
var _level_number := 0
var _current_beat := 0

#Variables for interrupting car advance for play if reset is pressed
var _initial_train_center_pos
var _advancing_car_for_play := false
var _advance_car_tween

# True when loaded level is a new world
var _queue_world_transition = false

# Keeps track of obstacles spawned in the level so they can be reset
var _spawned_obstacles : Array[MovableObstacle]

# Additional state variables
var _player_hidden = false
var _player_newly_hidden = false

func _ready() -> void:
	_level_scene = GameManager.level_catalog.get_level(GameManager.start_world, GameManager.start_level).instantiate()

	_on_the_train.add_child(_level_scene)
	add_child(_world_scene)

	_level_scene.position = initial_train_position

	AudioManager.play_music_event(level_catalog.get_world_music_event_name(), level_catalog.get_world_music_event_bpm())

	_initialize_level()
	_on_level_advanced()

	AudioManager.music_bar.connect(_on_music_bar)
	_action_sequencer.play_action_delay = train_move_right_on_play_time

	GameManager.pause_enabled = true
#endregion

#region Level Switching Management

## Loads next level into scene (does not initialize any functional components of that level)
func load_next_level():
	var _next_level_packed = GameManager.level_catalog.get_next_level()
	_queue_world_transition = GameManager.level_catalog.is_new_world()
	if _next_level_packed != null:
		_next_level = _next_level_packed.instantiate()
	else: # for now, break if loading past game end
		printerr("Attempting to load level beyond end of catalog. Loading 0,0 instead")
		_next_level = GameManager.level_catalog.get_level(0,0).instantiate()
	_on_the_train.call_deferred("add_child", _next_level)
	_next_level.position = initial_train_position + (_level_number+1) * Vector2(next_car_offset, 0.0)

## Pysically advances the level and initializes the new car with proper timing
func advance_level():
	_level_number += 1

	# Update reference to new level and initialize
	_level_scene = _next_level
	_initialize_level()

	# Tween to control animation of one train car to the next
	var tween = create_tween()
	var target_pos = _train_center.position + Vector2(-next_car_offset - train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, train_car_advance_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_level_advanced)


## Scene initialization steps that are called AFTER the level has been fully advanced
func _on_level_advanced():
	_action_sequencer.set_action_icons_hidden(false)
	_spawn_player()
	_reset_level()

# Handle connecting to signals, running initialization code for agents in new level
func _initialize_level():
	# Initialize new obstacles and pushers
	_initialize_moving_obstacles()
	_initialize_pushers()
	_initialize_interactables()
	_initialize_lasers()
	_initialize_teleporters()
	_initialize_antennas()

	# Connect to level finished signal
	_level_scene.connect("target_reached", _on_level_complete)

	# Update sequencer with new level data
	_action_sequencer.update_sequencer_data(_level_scene.available_slots, _level_scene.available_actions,
		_level_scene.action_quantities)
	_action_sequencer.tutorial_mode = _level_scene.tutorial_mode

	# Connect to animation signals from agents
	for agent in _level_scene.agents:
		if not agent.animation_signal.is_connected(_on_animation_signal_received):
			agent.animation_signal.connect(_on_animation_signal_received)

	# load following level
	load_next_level()

func _on_level_complete() -> void:
	_player_character.disable_collisions() # I don't think this line does anything important anymore, I'm just a bit nervous to take it out
	_player_character.notify_success()
	for collectible in _level_scene.collectibles:
		collectible.collect_if_queued()
	_action_sequencer.buttons_enabled = false

	_action_sequencer.stop_sequencer()
	await get_tree().create_timer(level_success_delay).timeout

	if _queue_world_transition:
		_execute_world_transition()
		return

	advance_level()

func _on_level_fail() -> void:
	_action_sequencer.buttons_enabled = false
	_action_sequencer.stop_sequencer()
	if _conductor != null:
		_conductor.visible = false
	await get_tree().create_timer(level_failure_delay).timeout
	_action_sequencer.buttons_enabled = true
	_action_sequencer.push_replay_button()

func _reset_level() -> void:
	print("level reset")
	_current_beat = 0
	if _conductor != null:
		_conductor.queue_free()
	_conductor = null
	_player_hidden = false
	_player_newly_hidden = false
	if _level_scene.conductor_enabled:
		_action_sequencer.conductor_spawned_countdown = _level_scene.conductor_spawn_beat
	else:
		_action_sequencer.conductor_spawned_countdown = 0

	_fade_to_thinking_shader()
	_action_sequencer.buttons_enabled = true

	for obstacle in _level_scene.movable_obstacles:
		_level_scene.update_obstacle_grid(obstacle.grid_position, true)
		obstacle.reset()
	for collectible in _level_scene.collectibles:
		collectible.reset()
	for interactable in _level_scene.interactables:
		interactable.reset()
	for obstacle in _spawned_obstacles: # clear out spawned obstacles
		_level_scene.movable_obstacles.erase(obstacle)
		_level_scene.update_obstacle_grid(obstacle.grid_position, true)
		obstacle.queue_free()
	_player_character.reset()
	_spawned_obstacles.clear()

func _on_reset_animation_finished():
	_action_sequencer.set_action_icons_hidden(false)
	# TODO: maybe put a reset animation here
	_player_character.enable_collisions()

## Run once final world level complete (i.e. new world level already loaded)
func _execute_world_transition():
	AudioManager.play_world_complete_music()
	var transition_scene = level_catalog.get_transition_scene().instantiate()
	assert(transition_scene is WorldTransitionTunnel)
	await AudioManager.music_complete
	add_child(transition_scene)
	AudioManager.play_music_event(level_catalog.get_world_music_event_name(), level_catalog.get_world_music_event_bpm())
	await get_tree().create_timer(transition_scene.get_time_until_screen_covered()).timeout
	_world_scene.queue_free()
	_world_scene = GameManager.level_catalog.get_world_scene().instantiate()
	add_child(_world_scene)
	advance_level()

#endregion

#region Level Component Initializations
# instantiates the movable, adds it to the level, places it into the correct spot
func _spawn_movable(scene: PackedScene, grid_position: Vector2i) -> Movable:
	var movable = scene.instantiate()
	_initialize_movable(movable, grid_position)
	_level_scene.add_child(movable)
	return movable

func _initialize_movable(movable: Agent, grid_position: Vector2i, should_reset = true) -> void:
	movable.grid_position = grid_position
	movable.grid_origin = grid_position
	movable.local_origin = _level_scene.map_to_local(Vector2i.ZERO)
	movable.tile_size = _level_scene.get_tile_size()
	if not movable.is_connected("animation_signal", _on_animation_signal_received):
		movable.animation_signal.connect(_on_animation_signal_received)
	if should_reset:
		movable.reset()

func _spawn_player() -> void:
	if _player_character != null:
		_player_character.queue_free()
	_player_character = _spawn_movable(player_scene, _level_scene.player_spawn_position)
	_player_character.failure.connect(_on_level_fail)

func _spawn_conductor() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = _spawn_movable(conductor_scene, _level_scene.conductor_spawn_position)
	if not _player_hidden:
		_conductor.state = Enums.ConductorState.PURSUE

func _initialize_moving_obstacles() -> void:
	for obstacle in _level_scene.movable_obstacles:
		_initialize_movable(obstacle, _level_scene.global_to_map(obstacle.global_position))
		obstacle.request_offbeat_action.connect(_on_obstacle_request_offbeat_action)
	for spawner in _level_scene.obstacle_spawners:
		spawner.obstacle_spawned.connect(_on_obstacle_spawned)

func _on_obstacle_spawned(obstacle: PackedScene, grid_position: Vector2i):
	var spawned_obstacle : MovableObstacle = _spawn_movable(obstacle, grid_position)
	if spawned_obstacle.pusher:
		spawned_obstacle.pusher.connect("overlapped_movable", _on_pusher_triggered)
	_level_scene.movable_obstacles.append(spawned_obstacle)
	_spawned_obstacles.append(spawned_obstacle)
	_level_scene.update_obstacle_grid(spawned_obstacle.grid_position, false)

func _initialize_interactables() -> void:
	for interactable: Interactable in _level_scene.interactables:
		_initialize_movable(interactable, _level_scene.global_to_map(interactable.global_position))
		interactable.updated_position.connect(_on_interactable_updated_position)
		if interactable is HideBench:
			interactable.started_hiding.connect(_hide_player.bind(true))
			interactable.finished_hiding.connect(_hide_player.bind(false))

##Reinitialize interactable to updated position if it calls that its position was updated
func _on_interactable_updated_position(interactable: Interactable, new_global_position: Vector2):
	_initialize_movable(interactable, _level_scene.global_to_map(interactable.global_position), false)

func _hide_player(new_hide_status: bool):
	_player_hidden = new_hide_status
	_player_newly_hidden = new_hide_status
	if new_hide_status:
		_player_character.disable_collisions()
	else:
		#_player_character.play_animation_with_follow_on("unhide", "idle_down")
		_player_character.enable_collisions()
		_update_conductor_awareness()

func _initialize_pushers() -> void:
	for pusher in _level_scene.pushers:
		pusher.connect("overlapped_movable", _on_pusher_triggered)

func _initialize_lasers() -> void:
	for laser: Laser in _level_scene.lasers:
		laser.direction_changed.connect(_update_laser_firing_distance)
		_update_laser_firing_distance(laser)

##Update max laser firing distance based on level static obstacles
func _update_laser_firing_distance(laser: Laser) -> void:
	var cells_to_obstacle = _level_scene.get_cells_to_obstacle(laser.grid_position, laser.direction)
	var cells_to_wall = _level_scene.get_cells_to_level_edge(laser.grid_position, laser.direction)
	laser.set_max_fire_distance_by_grid_spaces(cells_to_obstacle, cells_to_obstacle == cells_to_wall)

func _initialize_antennas() -> void:
	#for terminal: Terminal in _level_scene.terminals:
		#terminal.selected.connect(_on_terminal_selected)
	for antenna: Antenna in _level_scene.antennas:
		antenna.selected.connect(_on_antenna_selected)

func _initialize_teleporters() -> void:
	for teleporter: Teleporter in _level_scene.teleporters:
		# set a high value of traversing through a teleporter to discourage the conductor from going
		# into the teleporter accidentally. The player can force the conductor into going through,
		# but only if there is no other path
		_level_scene.update_weight_grid(teleporter.grid_position, 99.0)

#endregion

#region Beat Actions
# Called when sequencer emits an action in play mode
func _on_action_performed(action: Enums.PlayerAction) -> void:
	_update_obstacles() # Need to be updated first so player and conductor movement take new grid into account
	if action == Enums.PlayerAction.INTERACT:
		_update_interactables()
	_update_player(action)
	_update_conductor()
	_update_agents()
	_current_beat += 1

# Called when sequencer emits an action in thinking mode
func _on_thinking_action_performed():
	_update_obstacles()
	_update_agents()
	_current_beat += 1

func _update_obstacles():
	# check for actions before grid is updated (so obstacles can move into the same square triggering a push)
	var actions: Dictionary #Dictionary[MovableObstacle, Enums.PlayerAction]
	for obstacle: MovableObstacle in _level_scene.movable_obstacles:
		actions.get_or_add(obstacle, _bonk_check(obstacle, obstacle.get_next_move()))

	for obstacle in _level_scene.movable_obstacles:
		obstacle.execute_action(_bonk_check(obstacle, actions[obstacle]), _current_beat)
		#only update the move cursor if the action was executed (per the activation sequence)
		if obstacle.check_activation_for_beat(_current_beat):
			obstacle.advance_move_cursor()
	_level_scene.clear_obstacle_overrides()
	for obstacle in _level_scene.movable_obstacles:
		if obstacle.enabled:
			_level_scene.update_obstacle_grid(obstacle.grid_position, false)

## Callback for when obstacle wants to move off beat, so level manager can still update grid and resolve disputes
func _on_obstacle_request_offbeat_action(obstacle: MovableObstacle, desired_action: Enums.PlayerAction):
	_level_scene.update_obstacle_grid(obstacle.grid_position, true)
	obstacle.execute_action(_bonk_check(obstacle, desired_action), -1)
	obstacle.advance_move_cursor()
	_level_scene.update_obstacle_grid(obstacle.grid_position, false)


func _update_player(action: Enums.PlayerAction) -> void:
	if _player_newly_hidden or not _player_hidden:
		_player_newly_hidden = false
		_player_character.execute_action(_bonk_check(_player_character, action), _current_beat)

func _update_conductor() -> void:
	if not _level_scene.conductor_enabled:
		return
	elif _conductor == null \
		and _current_beat < _level_scene.conductor_spawn_beat:
		_action_sequencer.conductor_spawned_countdown = \
			_level_scene.conductor_spawn_beat - _current_beat
		return
	elif _conductor == null:
		_spawn_conductor()
		_action_sequencer.conductor_spawned_countdown = 0
	_update_conductor_awareness()
	# Target next train car if player's hidden
	var target = _player_character.grid_position if _conductor.state != Enums.ConductorState.UNAWARE else _level_scene.target_position
	var conductor_path = _level_scene.path_grid \
		.get_id_path(_conductor.grid_position, target, true)

	# find path state
	var traversible = true
	var reached = conductor_path.size() < 2
	for node in conductor_path:
		if node[0] < 0 or node[1] < 0:
			traversible = false
			break

	if reached:
		# catch the seated player
		if _conductor.state != Enums.ConductorState.UNAWARE and _player_hidden:
			_hide_player(false) # optionally, another failure animation
		return

	# launch the animation only once
	if not traversible and _conductor.state != Enums.ConductorState.UNREACHABLE:
		_conductor.state = Enums.ConductorState.UNREACHABLE_START

	# skip the next action if the conductor is trying to leave the map
	if conductor_path[1][0] < 0 or conductor_path[1][1] < 0:
		return
	_conductor.execute_action(
		_bonk_check(_conductor, Enums.vector_to_player_action(conductor_path[1] - _conductor.grid_position)),
		_current_beat
	)

##Use conductor facing direction, player hide status and position to determine if conductor should become aware
func _update_conductor_awareness():
	if not _conductor:
		return

	match _conductor.state:
		# a little state machine for conductor awareness
		# the conductor can lose the player when not hiding
		Enums.ConductorState.PURSUE:
			if _player_hidden:
				_conductor.state = Enums.ConductorState.ANGRY
				_conductor.play_current_emotion()
		Enums.ConductorState.UNAWARE:
			if _player_hidden:
				return
			var new_awareness := true
			if _conductor.facing_direction == Enums.Direction.LEFT:
				new_awareness = _player_character.grid_position.x <= _conductor.grid_position.x
			else:
				new_awareness = _player_character.grid_position.x >= _conductor.grid_position.x

			if new_awareness:
				_conductor.state = Enums.ConductorState.FOUND
		Enums.ConductorState.FOUND:
			_conductor.play_current_emotion()
			_conductor.state = Enums.ConductorState.PURSUE
		Enums.ConductorState.ANGRY:
			pass
		Enums.ConductorState.UNREACHABLE_START:
			_conductor.play_current_emotion()
			_conductor.state = Enums.ConductorState.UNREACHABLE
		Enums.ConductorState.UNREACHABLE:
			pass


func _update_interactables() -> void:
	for interactable : Interactable in _level_scene.interactables:
		if interactable.is_in_range(_player_character.grid_position) and interactable.can_interact():
			interactable.update_player_animation_based_on_position(_player_character.grid_position)
			_player_character.action_animations.set(Enums.PlayerAction.INTERACT, interactable.player_animation_on_success)
			_player_character.follow_on_animations.set(Enums.PlayerAction.INTERACT, interactable.follow_on_animation_on_success)
			interactable.execute_action(Enums.PlayerAction.INTERACT, _current_beat)
			return #Only one interactable should be triggered at a time--keep this in mind for level design
	_player_character.action_animations.set(Enums.PlayerAction.INTERACT, "")
	_player_character.follow_on_animations.set(Enums.PlayerAction.INTERACT, "")


## If desired direction clear, return that direction. Otherwise return a bonk in that direction
func _bonk_check(movable: Movable, action: Enums.PlayerAction) -> Enums.PlayerAction:
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _level_scene.get_traversible_neighbors(movable.grid_position).has(movable.grid_position + move_direction):
		return action
	else:
		return Enums.action_to_bonk(action)

func _update_agents() -> void:
	for agent in _level_scene.agents:
		if agent is not Movable and agent is not Interactable: # movables are sorted out into their own update functions
			agent.execute_action(Enums.PlayerAction.NONE, _current_beat, false)

func _on_pusher_triggered(pusher: Pusher, movable: Movable):
	movable.interrupt_queued_action(pusher.should_cancel_sound)
	var was_a_slide = Enums.is_action_slide(pusher.push_action)
	var action = _bonk_check(movable, pusher.push_action)
	if movable is PlayerCharacter:
		# Fail if crushed (i.e. a fall would result in a bonk)
		if Enums.is_action_bonk(action):
			_player_character.notify_failure(Enums.FailureCause.SQUISHED)
			_on_level_fail()
		else:
			_player_character.execute_action(action, _current_beat)
	elif movable is MovableObstacle:
		_level_scene.update_obstacle_grid(movable.grid_position, true)
		# skip animation if bonk was caused by a slide
		movable.execute_action(action, _current_beat, was_a_slide)
		_level_scene.update_obstacle_grid(movable.grid_position, false)
	else: # conductor
		movable.execute_action(action, _current_beat)

#endregion

#region Sequencer Callbacks
func _on_action_sequencer_play_started() -> void:
	_current_beat = 0
	_advance_car_for_play(train_move_right_on_play_time)
	_fade_to_running_shader()
	for obstacle in _level_scene.movable_obstacles:
		_level_scene.update_obstacle_grid(obstacle.grid_position, true)
		obstacle.reset()

func _advance_car_for_play(animation_time: float):
	_advancing_car_for_play = true
	_advance_car_tween = create_tween()
	_initial_train_center_pos = _train_center.position
	var target_pos := Vector2(-_level_number * next_car_offset + train_move_right_on_play_distance, 0)
	_advance_car_tween.tween_property(_train_center, "position", target_pos, animation_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_advance_car_tween.tween_callback(_on_advance_for_play_finished)

func _on_advance_for_play_finished():
	_advancing_car_for_play = false

func _on_action_sequencer_replay_pressed() -> void:
	_player_character.disable_collisions()
	if _advancing_car_for_play:
		_train_center.position = _initial_train_center_pos
		_on_advance_for_play_finished()
		_advance_car_tween.kill()
		_on_reset_animation_finished()
	else:
		var tween = create_tween()
		var target_pos := Vector2(-_level_number * next_car_offset, 0)
		tween.tween_property(_train_center, "position", target_pos, train_move_right_on_play_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_on_reset_animation_finished)
	_reset_level()

func _fade_to_running_shader():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_shader.material, "shader_parameter/bcs", Vector3(1,1,1), filter_animation_time)
	tween.tween_property(_shader.material, "shader_parameter/vignette", 0.0, filter_animation_time)
	tween.tween_property(_shader.material, "shader_parameter/wipe", -1.0, filter_animation_time)


func _fade_to_thinking_shader():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_shader.material, "shader_parameter/bcs",
		Vector3(brightness, contrast, saturation), filter_animation_time)
	tween.tween_property(_shader.material, "shader_parameter/vignette", 1.0, filter_animation_time)
	tween.tween_property(_shader.material, "shader_parameter/wipe", 1.0, filter_animation_time)

func _on_antenna_selected(new_antenna: Antenna):
	for antenna: Antenna in _level_scene.antennas:
		antenna.set_active_animation(false)
	new_antenna.set_active_animation(true)
	_lightning.global_position = new_antenna.get_sprite_global_position()
	_lightning.points[1] = _action_sequencer.antenna_tip.global_position - _lightning.global_position
	_lightning.visible = true
	_shake_camera.apply_shake(lightning_sreen_shake_strength, lightning_screen_shake_decay)
	_action_sequencer.connect_antenna_to_screen(new_antenna.programs[0]) #Only makes sense to connect single program to screen
	await get_tree().create_timer(lightning_duration).timeout
	_lightning.visible = false
	# if you crashed here you probably forgot to add a terminal program to a terminal or an antenna
#endregion

#region Animation
func _on_music_bar():
	_animation_player.play("train_rock")

func _on_animation_signal_received(signal_id: String):
	match signal_id:
		"door_slammed":
			_shake_camera.apply_shake()
#endregion

#region Debug
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipLevel"):
		_advance_car_for_play(0.0)
		advance_level()

#endregion
