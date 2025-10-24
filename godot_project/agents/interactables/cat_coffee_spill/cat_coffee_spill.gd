extends Interactable

## Two obstacle spawners for an obstacle that spans 2 tiles (only one has the visuals)
@onready var obstacle_spawner_visible := $VisibleObstacleSpawner
@onready var obstacle_spawner_invisible := $InvisibleObstacleSpawner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	interaction_succeeded.connect(_on_successful_interaction)

func _on_successful_interaction():
	sprite.play_with_signals("wake_up")
	await sprite.animation_signal # only signal is the spilled coffee signal, so await without checking signal id is ok
	obstacle_spawner_visible.spawn_obstacle(grid_position)
	obstacle_spawner_invisible.spawn_obstacle(grid_position)
	await sprite.animation_finished
	sprite.play_with_signals("idle")
