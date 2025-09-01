extends Node2D

@export var CollectibleType := Enums.Collectibles.GENERIC

@onready var collision_shape = $Shadow/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func collect(type: Enums.Collectibles):
	GameManager.add_to_inventory(type)

func _on_collision_shape_2d_area_entered(area: Area2D) -> void:
	collect(CollectibleType)
	pass # Replace with function body.
