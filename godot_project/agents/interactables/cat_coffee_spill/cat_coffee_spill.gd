extends Interactable

## Two obstacle spawners for an obstacle that spans 2 tiles (only one has the visuals)
@onready var obstacle_spawner_visible := $VisibleObstacleSpawner
@onready var obstacle_spawner_invisible := $InvisibleObstacleSpawner
@onready var original_visible_grid_offset_x = obstacle_spawner_visible.grid_offset.x
@onready var original_invisible_grid_offset_x = obstacle_spawner_visible.grid_offset.x
#@onready var sound := $FmodEventEmitter2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	interaction_succeeded.connect(_on_successful_interaction)

func _on_flip_horizontal(new_flip_status):
	super._on_flip_horizontal(new_flip_status)
	if not obstacle_spawner_visible or not obstacle_spawner_invisible:
		return
	if new_flip_status:
		obstacle_spawner_visible.grid_offset.x = -original_visible_grid_offset_x
		obstacle_spawner_invisible.grid_offset.x = -original_invisible_grid_offset_x
	else:
		obstacle_spawner_visible.grid_offset.x = original_visible_grid_offset_x
		obstacle_spawner_invisible.grid_offset.x = original_invisible_grid_offset_x

func update_player_animation_based_on_position(player_grid_position: Vector2i):
	var relative_grid_position = player_grid_position - grid_position
	match relative_grid_position:
		Vector2i.UP:
			player_animation_on_success = "pet_down"
		Vector2i.DOWN:
			player_animation_on_success = "pet_up"
		Vector2i.LEFT:
			player_animation_on_success = "pet_right"
		Vector2i.RIGHT:
			player_animation_on_success = "pet_left"
		_:
			push_error("No cat pet animation found for relative grid position ", relative_grid_position)

func _on_successful_interaction():
	#sprite.play_with_signals("wake_up")
	await sprite.animation_signal # only signal is the spilled coffee signal, so await without checking signal id is ok
	#sound.play()
	obstacle_spawner_visible.spawn_obstacle(grid_position)
	obstacle_spawner_invisible.spawn_obstacle(grid_position)
	#await sprite.animation_finished
	#sprite.play_with_signals("idle")
