extends Node2D

@onready var sprite = $Sprite
@onready var collision = $Collision/CollisionShape2D
@onready var beam = $Beam
@onready var animation_player = $AnimationPlayer

## Length of the laser beam
@export var beam_length := 2
## Size of the beam collision per each tile
@export var beam_tile_size := Vector2i(16, 20)

func _ready() -> void:
	collision.shape.size = Vector2i(beam_tile_size.x, beam_tile_size.y * beam_length + 1)
	collision.disabled = true
	collision.position = Vector2i.DOWN * beam_tile_size.y * beam_length * 0.5


func fire() -> void:
	sprite.play("fire")
	animation_player.play("laser_fire")


func _input(event: InputEvent) -> void:
	if event.is_action("DebugAction"):
		fire()
