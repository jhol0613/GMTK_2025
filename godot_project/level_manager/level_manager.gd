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

@export_category("Levels")
## All train cars in order
@export var level_list: Array[PackedScene]


@onready var _level_scene : RhythmRailLevel
@onready var _action_sequencer : ActionSequencer = $ActionSequencer
@onready var _on_the_train : = $TrainCenter/OnTheTrain
# needs to exist since you can't animate x and y values for on the train separately, don't want train rock
# animation to reset train horizontal position
@onready var _train_center: = $TrainCenter
@onready var _animation_player := $AnimationPlayer


var _conductor: Conductor
var _player_character: PlayerCharacter

var _next_level: RhythmRailLevel
var _level_number := 0
var _current_beat := 0

func _ready() -> void:
	_level_scene = level_list[0].instantiate()
	_on_the_train.add_child(_level_scene)

	_level_scene.position = initial_train_position

	_spawn_player()

	# Currently just uses default action quantities
	_action_sequencer.update_sequencer_data(_level_scene.available_slots, _level_scene.available_actions)

	AudioManager.music_bar.connect(_on_music_bar)
	_action_sequencer.play_action_delay = train_move_right_on_play_time

	_level_scene.connect("target_reached", _on_level_complete)
	load_next_level()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipLevel"):
		advance_level()

func load_next_level():
	_next_level = level_list[(_level_number + 1) % level_list.size()].instantiate()
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

	# load following level
	load_next_level()


# Called when level has been fully advanced
func _on_level_advanced():
	_action_sequencer.set_action_icons_hidden(false)

	_spawn_player()
	_reset_level()


func _on_action_performed(action: Enums.PlayerAction) -> void:
	_update_player(action)
	_update_conductor()
	_update_lasers()
	_current_beat += 1


func _update_player(action: Enums.PlayerAction) -> void:
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _level_scene.get_traversible_neighbors(_player_character.grid_position).has(_player_character.grid_position + move_direction):
		_player_character.execute_action(action)
	else: #directional bonks
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


func _update_lasers() -> void:
	for laser in _level_scene.lasers:
		laser.fire(_current_beat)


# instantiates the agent, adds it to the level, places it into the correct spot
func _spawn_agent(scene: PackedScene, grid_position: Vector2i) -> Agent:
	var agent = scene.instantiate()
	agent.grid_position = grid_position
	agent.grid_origin = grid_position
	agent.local_origin = _level_scene.map_to_local(Vector2i.ZERO)
	agent.tile_size = _level_scene.get_tile_size()
	_level_scene.add_child(agent)
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


func _reset_level() -> void:
	if _conductor != null:
		_conductor.queue_free()
	_conductor = null

	_current_beat = 0


func _on_music_bar():
	_animation_player.play("train_rock")


func _on_action_sequencer_play_started() -> void:
	var tween = create_tween()
	var target_pos := Vector2(-_level_number * next_car_offset + train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, train_move_right_on_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _on_action_sequencer_replay_pressed() -> void:
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


func _on_level_fail() -> void:
	_action_sequencer.stop_sequencer()
	if _conductor != null:
		_conductor.visible = false
	await get_tree().create_timer(level_failure_delay).timeout
	_action_sequencer.push_replay_button()
