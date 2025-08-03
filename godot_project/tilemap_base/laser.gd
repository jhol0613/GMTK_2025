extends Node2D

class_name Laser

@onready var sprite = $Sprite
@onready var collision = $Collision/CollisionShape2D
@onready var beam = $Beam
@onready var animation_player = $AnimationPlayer

## Length of the laser beam
@export var beam_length := 2
## Size of the beam collision per each tile
@export var beam_tile_size := Vector2i(16, 20)
## Beat sequence: for each item in the array, on that beat the laser will fire/not fire
@export var activation_sequence: Array[bool] = [false, true]

func _ready() -> void:
	collision.shape.size = Vector2i(beam_tile_size.x, beam_tile_size.y * beam_length + 1)
	collision.disabled = true
	collision.position = Vector2i.DOWN * beam_tile_size.y * beam_length * 0.5


func fire(beat: int) -> void:
	if activation_sequence[beat % activation_sequence.size()]:
		sprite.play("fire")
		animation_player.play("laser_fire")


func _input(event: InputEvent) -> void:
	if event.is_action("DebugAction"):
		fire(0)
