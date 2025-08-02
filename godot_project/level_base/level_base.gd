extends Node2D

# Baseline for all levels. A Level will include a tilemap level, a sequencer, a player character
# instance, and any agents that will be performing actions. Received signals from the sequencer
# and directs movement and actions of agents on the tilemap

@export_subgroup("Conductor", "conductor")
@export var conductor_scene: PackedScene
## Where on the tilemap the conductor should spawn
@export var conductor_spawn_position: Vector2i

@export_subgroup("Animation")
@export var train_move_right_on_play_distance := 56.0
@export var train_move_right_on_play_time := 1.8
@export var next_car_offset := 490
@export var train_car_advance_play_time := 2.5

@onready var _player_character : PlayerCharacter = $TrainCenter/OnTheTrain/PlayerCharacter
@onready var _tilemap_level : TilemapLevel = $TrainCenter/OnTheTrain/TilemapLevel
@onready var _action_sequencer : ActionSequencer = $ActionSequencer
@onready var _on_the_train : = $TrainCenter/OnTheTrain
# needs to exist since you can't animate x and y values for on the train separately, don't want train rock
# animation to resest train horizontal position
@onready var _train_center: = $TrainCenter
@onready var _animation_player := $AnimationPlayer

@onready var _initial_train_posit = _tilemap_level.position
@onready var _initial_player_posit = _player_character.global_position

var tile_size: Vector2i
var _conductor: Conductor

var _next_tile_level: TilemapLevel
var _level_number := 0

func _ready() -> void:
	_player_character.grid_position = _tilemap_level.global_to_map(_initial_player_posit)
	_player_character.tile_size = _tilemap_level.get_tile_size()

	AudioManager.music_bar.connect(_on_music_bar)
	_action_sequencer.play_action_delay = train_move_right_on_play_time

	_tilemap_level.connect("target_reached", _on_level_complete)
	load_next_tile_level()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipLevel"):
		advance_level()

func load_next_tile_level():
	_next_tile_level = load(_tilemap_level.next_level_path).instantiate()
	_on_the_train.add_child(_next_tile_level)
	_next_tile_level.position = _initial_train_posit + (_level_number+1) * Vector2(next_car_offset, 0.0)

func advance_level():
	_level_number += 1
	# load following tilemap level
	load_next_tile_level()

	# Tween to control animation of one train car to the next
	var advance_distance = ProjectSettings.get_setting("display/window/size/viewport_width")
	var tween = create_tween()
	var target_pos = _train_center.position + Vector2(-next_car_offset - train_move_right_on_play_distance, 0)
	tween.tween_property(_train_center, "position", target_pos, train_car_advance_play_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_level_advanced)

	# Update tilemap reference to new level and connect to signals
	_tilemap_level = _next_tile_level
	_tilemap_level.connect("target_reached", _on_level_complete)

	# Load the new appropriate sequencer level
	var sequencer_posit = _action_sequencer.global_position
	_action_sequencer.queue_free()
	_action_sequencer = load(_tilemap_level.associated_sequencer_level).instantiate()
	add_child(_action_sequencer)
	_action_sequencer.set_action_icons_hidden(true)
	_action_sequencer.global_position = sequencer_posit
	_action_sequencer.connect("play_started", _on_action_sequencer_play_started)
	_action_sequencer.connect("replay_pressed", _on_action_sequencer_replay_pressed)

# Called when level has been fully advanced
func _on_level_advanced():
	_action_sequencer.set_action_icons_hidden(false)


func _on_action_performed(action: Enums.PlayerAction) -> void:
	_update_player(action)
	_update_conductor()


func _update_player(action: Enums.PlayerAction) -> void:
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _tilemap_level.get_traversible_neighbors(_player_character.grid_position).has(_player_character.grid_position + move_direction):
		_player_character.grid_position += move_direction
		_player_character.execute_action(action)


func _update_conductor() -> void:
	if _conductor == null:
		return
	var conductor_path = _tilemap_level.path_grid \
		.get_id_path(_conductor.grid_position, _player_character.grid_position, true)
	_conductor.execute_action(
		Enums.vector_to_player_action(_conductor.grid_position - conductor_path[1])
	)


func _spawn_conductor() -> void:
	_conductor = conductor_scene.instantiate()
	_conductor.grid_position = conductor_spawn_position
	_conductor.tile_size = _tilemap_level.get_tile_size()
	add_child(_conductor)

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

func _on_car_position_moved_back():
	_action_sequencer.set_action_icons_hidden(false)

func _on_level_complete() -> void:
	advance_level()
