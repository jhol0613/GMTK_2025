extends Node2D

class_name ObstacleSpawner

signal obstacle_spawned(Obstacle: MovableObstacle, grid_location: Vector2i)

@export var obstacle_scene : PackedScene
## Where to offset spawned obstacle from spawner position
@export var grid_offset: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("obstacle_spawners")

##Emits signal with packed scene and a location. Still needs to be added to scene by level manager
func spawn_obstacle(grid_location: Vector2i, delay := 0.0):
	await get_tree().create_timer(delay).timeout
	obstacle_spawned.emit(obstacle_scene, grid_location + grid_offset)
