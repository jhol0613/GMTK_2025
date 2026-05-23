extends Collectible

class_name LevelKey

signal key_collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("keys")

func _on_collision_shape_2d_area_entered(area) -> void:
	super._on_collision_shape_2d_area_entered(area)
	key_collected.emit()
