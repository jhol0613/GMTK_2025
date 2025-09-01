extends Node2D


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

# Prevents registering replay button while success animation is playing
var _replay_enabled := true 

func _ready() -> void:
	_level_scene = GameManager.level_catalog.get_level(GameManager.start_world, GameManager.start_level).instantiate()
	
	#_level_scene = level_list[0].instantiate()
	_on_the_train.add_child(_level_scene)
	add_child(_world_scene)

	_level_scene.position = initial_train_position

	_spawn_player()

	# Currently just uses default action quantities
	_action_sequencer.update_sequencer_data(_level_scene.available_slots, _level_scene.available_actions)

	AudioManager.music_bar.connect(_on_music_bar)
	_action_sequencer.play_action_delay = train_move_right_on_play_time

	_level_scene.connect("target_reached", _on_level_complete)
	load_next_level()
	
	# Turn on thinking mode
	_reset_level()
	
	GameManager.pause_enabled = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipLevel"):
		_advance_car_for_play(0.0)
		advance_level()

func load_next_level():
	#_next_level = level_list[(_level_number + 1) % level_list.size()].instantiate()
	var _next_level_packed = GameManager.level_catalog.get_next_level()
	if _next_level_packed != null:
		_next_level = _next_level_packed.instantiate()
	else: # for now, loop to first level at game end
		_next_level = GameManager.level_catalog.get_level(0,0).instantiate()
	if GameManager.level_catalog.is_new_world():
		print("New World level loaded")
	_on_the_train.call_deferred("add_child", _next_level)
	_next_level.position = initial_train_position + (_level_number+1) * Vector2(next_car_offset, 0.0)

func advance_level():
	_level_number += 1

	_action_sequencer.stop_sequencer()
	await get_tree().create_timer(level_success_delay).timeout

	# Tween to control animation of one train car to the next
	var tween = create_tween()
	var target_pos = _train_center.position + Vector2(-next_car_offset - train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, train_car_advance_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_level_advanced)

	# Update reference to new level and connect to signals
	_level_scene = _next_level
	_level_scene.connect("target_reached", _on_level_complete)

	# Update sequencer with new level data
	_action_sequencer.update_sequencer_data(_level_scene.available_slots, _level_scene.available_actions)
	
	# Connect to animation signals from static agents
	for agent in _level_scene.static_agents:
		agent.animation_signal.connect(_on_animation_signal_received)

	# load following level
	load_next_level()


# Called when level has been fully advanced
func _on_level_advanced():
	_action_sequencer.set_action_icons_hidden(false)
	_spawn_player()
	_reset_level()

# Called when sequencer emits an action in play mode
func _on_action_performed(action: Enums.PlayerAction) -> void:
	_update_player(action)
	_update_conductor()
	_update_agents()
	_current_beat += 1

# Called when sequencer emits an action in thinking mode
func _on_thinking_action_performed():
	_update_agents()
	_current_beat += 1


func _update_player(action: Enums.PlayerAction) -> void:
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _level_scene.get_traversible_neighbors(_player_character.grid_position).has(_player_character.grid_position + move_direction):
		_player_character.execute_action(action)
	else:
		match action:
			Enums.PlayerAction.LEFT:
				_player_character.execute_action(Enums.PlayerAction.LEFT_BONK)
			Enums.PlayerAction.RIGHT:
				_player_character.execute_action(Enums.PlayerAction.RIGHT_BONK)
			Enums.PlayerAction.UP:
				_player_character.execute_action(Enums.PlayerAction.UP_BONK)
			Enums.PlayerAction.DOWN:
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
	for agent in _level_scene.static_agents:
		agent.tick.emit(_current_beat)

# instantiates the agent, adds it to the level, places it into the correct spot
func _spawn_agent(scene: PackedScene, grid_position: Vector2i) -> Agent:
	var agent = scene.instantiate()
	agent.grid_position = grid_position
	agent.grid_origin = grid_position
	agent.local_origin = _level_scene.map_to_local(Vector2i.ZERO)
	agent.tile_size = _level_scene.get_tile_size()
	_level_scene.add_child(agent)
	agent.animation_signal.connect(_on_animation_signal_received)
	return agent

func _spawn_player() -> void:
	if _player_character != null:
		_player_character.queue_free()
	_player_character = _spawn_agent(player_scene, _level_scene.player_spawn_position)
	_player_character.failure.connect(_on_level_fail)

func _spawn_conductor() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = _spawn_agent(conductor_scene, _level_scene.conductor_spawn_position)

func _on_animation_signal_received(signal_id: String):
	match signal_id:
		"door_slammed":
			_shake_camera.apply_shake()

func _reset_level() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = null
	_current_beat = 0
	
	_fade_to_thinking_shader()
	_replay_enabled = true


func _on_music_bar():
	_animation_player.play("train_rock")


func _on_action_sequencer_play_started() -> void:
	_current_beat = 0
	_advance_car_for_play(train_move_right_on_play_time)
	_fade_to_running_shader()
 
func _advance_car_for_play(animation_time: float):
	var tween = create_tween()
	var target_pos := Vector2(-_level_number * next_car_offset + train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, animation_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _on_action_sequencer_replay_pressed() -> void:
	if not _replay_enabled:
		return
	var tween = create_tween()
	var target_pos := Vector2(-_level_number * next_car_offset, 0)
	tween.tween_property(_train_center, "position", target_pos, train_move_right_on_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_car_position_moved_back)
	_reset_level()


func _on_car_position_moved_back():
	_action_sequencer.set_action_icons_hidden(false)
	# TODO: maybe put a reset animation here
	_player_character.reset()


func _on_level_complete() -> void:
	_player_character.disable_collisions()
	_player_character.notify_success()
	advance_level()
	_replay_enabled = false
	

func _on_level_fail() -> void:
	_action_sequencer.stop_sequencer()
	if _conductor != null:
		_conductor.visible = false
	await get_tree().create_timer(level_failure_delay).timeout
	_action_sequencer.push_replay_button()

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
