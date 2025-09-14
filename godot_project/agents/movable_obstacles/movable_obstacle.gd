extends Movable

class_name MovableObstacle

@export_subgroup("Path")
@export var movement_path: Array[Vector2i]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tick.connect(_on_tick)

func _on_tick(beat: int) -> void:
	print("ticked")

func _on_action_executed(action: Enums.PlayerAction) -> void:
	print("action executed")
	pass
