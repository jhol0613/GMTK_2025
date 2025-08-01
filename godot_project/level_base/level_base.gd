extends Node2D

# Baseline for all levels. A Level will include a tilemap level, a sequencer, a player character
# instance, and any agents that will be performing actions. Received signals from the sequencer
# and directs movement and actions of agents on the tilemap

@export_subgroup("Conductor", "conductor")
@export var conductor_scene: PackedScene
## Where on the tilemap the conductor should spawn
@export var conductor_spawn_position: Vector2i

@onready var _player_character : PlayerCharacter = $OnTheTrain/PlayerCharacter
@onready var _tilemap_level : TilemapLevel = $OnTheTrain/TilemapLevel
@onready var _action_sequencer : ActionSequencer = $ActionSequencer
@onready var _on_the_train : = $OnTheTrain
@onready var _animation_player := $OnTheTrain/AnimationPlayer

@onready var _initial_train_posit = _on_the_train.position

var tile_size: Vector2i
var _conductor: Conductor


func _ready() -> void:
	_player_character.grid_position = _tilemap_level.global_to_map(_player_character.global_position)
	_player_character.tile_size = _tilemap_level.get_tile_size()
	
	AudioManager.music_bar.connect(_on_music_bar)


func _on_sequencer_level_placeholder_player_action_received(action: Enums.PlayerAction) -> void:
	_update_player(action)
	_update_conductor()


func _on_action_sequencer_perform_action(action: Enums.PlayerAction) -> void:
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
	print("on the bar")
	_animation_player.play("train_rock")
	
