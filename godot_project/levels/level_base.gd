extends Node2D

# Baseline for all levels. A Level will include a tilemap level, a sequencer, a player character
# instance, and any agents that will be performing actions. Received signals from the sequencer 
# and directs movement and actions of agents on the tilemap

var player_position: Vector2i
var tile_size: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Get player grid position based on their local coordinate
	player_position = $TilemapLevel/Floor.local_to_map($TilemapLevel/Floor.to_local($PlayerCharacter.global_position))
	
	tile_size = Vector2i($TilemapLevel.get_horizontal_tile_spacing(), $TilemapLevel.get_vertical_tile_spacing())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_sequencer_level_placeholder_player_action_received(action: Enums.PlayerAction) -> void:
	# Update player grid position, world position, and trigger action so player can deal with animation
	var move_direction : Vector2i = Enums.player_action_to_vector(action)
	player_position += move_direction
	$PlayerCharacter.global_position += Vector2(tile_size * move_direction)
	$PlayerCharacter.execute_action(action)
	#print(player_position)
