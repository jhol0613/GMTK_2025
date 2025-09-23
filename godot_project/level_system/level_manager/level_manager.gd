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
@export var train_move_right_on_play_time := 1.2
##The amount of time required for the level to visually advance
@export var train_car_advance_play_time := 2.5
@export_subgroup("Reset Delays")
## How long to wait before scrolling to the next level (e.g. to allow time for animation)
@export var level_success_delay := 2.0
## How long to wait to reset the level after a failure
@export var level_failure_delay := 2.0
@export_subgroup("Thinking Mode Filter")
@export_range(0, 1, .01) var brightness: float
@export_range(0, 1, .01) var contrast: float
@export_range(0, 1, .01) var saturation: float
@export var filter_animation_time := 1.5

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


var _conductor: Conductor
var _player_character: PlayerCharacter

var _next_level: RhythmRailLevel
var _level_number := 0
var _current_beat := 0

func _ready() -> void:
	_level_scene = GameManager.level_catalog.get_level(GameManager.start_world, GameManager.start_level).instantiate()

	_on_the_train.add_child(_level_scene)
	add_child(_world_scene)

	_level_scene.position = initial_train_position

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
	if _next_level_packed != null:
		_next_level = _next_level_packed.instantiate()
	else: # for now, loop to first level at game end
		_next_level = GameManager.level_catalog.get_level(0,0).instantiate()
	if GameManager.level_catalog.is_new_world():
		print("New World level loaded")
	_on_the_train.call_deferred("add_child", _next_level)
	_next_level.position = initial_train_position + (_level_number+1) * Vector2(next_car_offset, 0.0)

## Pysically advances the level and initializes the new car with proper timing
func advance_level():
	_level_number += 1

	_action_sequencer.stop_sequencer()
	await get_tree().create_timer(level_success_delay).timeout
	
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
	
	# Connect to level finished signal
	_level_scene.connect("target_reached", _on_level_complete)

	# Update sequencer with new level data
	_action_sequencer.update_sequencer_data(_level_scene.available_slots, _level_scene.available_actions, 
		_level_scene.action_quantities)
	_action_sequencer.tutorial_mode = _level_scene.tutorial_mode

	# Connect to animation signals from agents
	for agent in _level_scene.agents:
		agent.animation_signal.connect(_on_animation_signal_received)

	# load following level
	load_next_level()
	
func _on_level_complete() -> void:
	_player_character.disable_collisions() # I don't think this line does anything important anymore, I'm just a bit nervous to take it out
	_player_character.notify_success()
	for collectible in _level_scene.collectibles:
		collectible.collect_if_queued()
	advance_level()
	_action_sequencer.buttons_enabled = false
	
func _on_level_fail() -> void:
	_action_sequencer.buttons_enabled = false
	_action_sequencer.stop_sequencer()
	if _conductor != null:
		_conductor.visible = false
	await get_tree().create_timer(level_failure_delay).timeout
	_action_sequencer.buttons_enabled = true
	_action_sequencer.push_replay_button()

func _reset_level() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = null

	_fade_to_thinking_shader()
	_action_sequencer.buttons_enabled = true

	for collectible in _level_scene.collectibles:
		collectible.reset()

func _on_reset_animation_finished():
	_action_sequencer.set_action_icons_hidden(false)
	# TODO: maybe put a reset animation here
	_player_character.reset()
#endregion

#region Level Component Initializations
# instantiates the movable, adds it to the level, places it into the correct spot
func _spawn_movable(scene: PackedScene, grid_position: Vector2i) -> Movable:
	var movable = scene.instantiate()
	_initialize_movable(movable, grid_position)
	_level_scene.add_child(movable)
	return movable
	
func _initialize_movable(movable: Movable, grid_position: Vector2i) -> void:
	movable.grid_position = grid_position
	movable.grid_origin = grid_position
	movable.local_origin = _level_scene.map_to_local(Vector2i.ZERO)
	movable.tile_size = _level_scene.get_tile_size()
	movable.animation_signal.connect(_on_animation_signal_received)

func _spawn_player() -> void:
	if _player_character != null:
		_player_character.queue_free()
	_player_character = _spawn_movable(player_scene, _level_scene.player_spawn_position)
	_player_character.failure.connect(_on_level_fail)

func _spawn_conductor() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = _spawn_movable(conductor_scene, _level_scene.conductor_spawn_position)
	
func _initialize_moving_obstacles() -> void:
	for obstacle in _level_scene.movable_obstacles:
		_initialize_movable(obstacle, _level_scene.global_to_map(obstacle.global_position))
		
func _initialize_pushers() -> void:
	for pusher in _level_scene.pushers:
		print("pushe recognized by level manager")
		pusher.connect("overlapped_movable", _on_pusher_triggered)

#endregion

#region Beat Actions
# Called when sequencer emits an action in play mode
func _on_action_performed(action: Enums.PlayerAction) -> void:
	_update_obstacles() # Need to be updated first so player and conductor movement take new grid into account
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
	for obstacle in _level_scene.movable_obstacles:
		_level_scene.update_obstacle_grid(obstacle.grid_position, true)
		obstacle.execute_action(obstacle.get_next_move())
		_level_scene.update_obstacle_grid(obstacle.grid_position, false)

func _update_player(action: Enums.PlayerAction) -> void:
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _level_scene.get_traversible_neighbors(_player_character.grid_position).has(_player_character.grid_position + move_direction):
		_player_character.execute_action(action)
	else:
		match move_direction:
			Vector2i.LEFT:
				_player_character.execute_action(Enums.PlayerAction.LEFT_BONK)
			Vector2i.RIGHT:
				_player_character.execute_action(Enums.PlayerAction.RIGHT_BONK)
			Vector2i.UP:
				_player_character.execute_action(Enums.PlayerAction.UP_BONK)
			Vector2i.DOWN:
				_player_character.execute_action(Enums.PlayerAction.DOWN_BONK)

func _update_conductor() -> void:
	if _conductor == null \
		and _current_beat < _level_scene.conductor_spawn_beat \
		or not _level_scene.conductor_enabled:
		return
	if _conductor == null:
		_spawn_conductor()
	var conductor_path = _level_scene.path_grid \
		.get_id_path(_conductor.grid_position, _player_character.grid_position, true)
	if conductor_path.size() < 2:
		return
	_conductor.execute_action(
		Enums.vector_to_player_action(conductor_path[1] - _conductor.grid_position)
	)

func _update_agents() -> void:
	for agent in _level_scene.agents:
		agent.tick.emit(_current_beat)
		
func _on_pusher_triggered(pusher: Pusher, movable: Movable):
	movable.interrupt_queued_action(pusher.should_cancel_sound)
	if movable is PlayerCharacter:
		_update_player(pusher.push_action)
	else:
		movable.execute_action(pusher.push_action)

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
	var tween = create_tween()
	var target_pos := Vector2(-_level_number * next_car_offset + train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, animation_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _on_action_sequencer_replay_pressed() -> void:
	var tween = create_tween()
	var target_pos := Vector2(-_level_number * next_car_offset, 0)
	tween.tween_property(_train_center, "position", target_pos, train_move_right_on_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_reset_animation_finished)
	#_on_reset_animation_finished()
	_reset_level()
	_player_character.disable_collisions()

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
