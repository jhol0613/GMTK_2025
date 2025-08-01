extends Node2D

# Baseline for all levels. A Level will include a tilemap level, a sequencer, a player character
# instance, and any agents that will be performing actions. Received signals from the sequencer 
# and directs movement and actions of agents on the tilemap

@onready var _player_character : PlayerCharacter = $PlayerCharacter
@onready var _tilemap_level : TilemapLevel = $TilemapLevel
@onready var _action_sequencer : ActionSequencer = $ActionSequencer

var player_position: Vector2i
var tile_size: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(_player_character.global_position)
	#Get player grid position based on their local coordinate
	player_position = _tilemap_level.global_to_map(_player_character.global_position)
	#Get tilemap grid size so you can move agents by appropriate number of pixels for moves
	tile_size = Vector2i(_tilemap_level.get_horizontal_tile_spacing(), _tilemap_level.get_vertical_tile_spacing())
	
	_player_character.horizontal_action_distance = tile_size.x
	_player_character.vertical_action_distance = tile_size.y
	
	
	

func _on_sequencer_level_placeholder_player_action_received(action: Enums.PlayerAction) -> void:
	# Update player grid position, world position, and trigger action so player can deal with animation
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	if _tilemap_level.get_traversible_neighbors(player_position).has(player_position + move_direction):
		player_position += move_direction
		#_player_character.global_position += Vector2(tile_size * move_direction)
		_player_character.execute_action(action)
	#print(player_position)


func _on_action_sequencer_perform_action(type: int) -> void:
	print(type)
	pass # Replace with function body.
