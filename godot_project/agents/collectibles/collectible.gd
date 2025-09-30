extends Agent

class_name Collectible

@export_subgroup("collectible_data")
@export var type := Enums.CollectibleType.SAVED
@export var id := "None"

@export_subgroup("animation")
@export var collected_y_curve: Curve
@export var collected_scale_curve: Curve
@export var collected_y_magnitude := 70.0
@export var collected_duration := 1.0

@onready var collision_area = $Shadow/CollisionArea

@onready var _sprite_initial_position = sprite.position
#@onready var _actor_initial_position = global_position

@onready var queued_for_collect = false


func _ready() -> void:
	super._ready()
	add_to_group("collectibles")

## Saves a collectible to the save file if it's been queued for collect
func collect_if_queued():
	if type == Enums.CollectibleType.SAVED and queued_for_collect:
		GameManager.save_collectible(id)

func reset():
	visible = true
	collision_area.set_collision_layer_value(3, true)
	queued_for_collect = false
	sprite.scale = Vector2(1,1)
	sprite.play("default")
	#super.reset()

func _on_collision_shape_2d_area_entered(area: Area2D) -> void:
	collision_area.collision_layer = 0;
	queued_for_collect = true
	var tween = create_tween()
	tween.tween_method(_triggered_callback.bind(), 0.0, 1.0, collected_duration)
	tween.connect("finished", _on_triggered)

func _triggered_callback(alpha: float):
	sprite.position.y = -collected_y_curve.sample(alpha) * collected_y_magnitude + _sprite_initial_position.y
	sprite.scale.x = collected_scale_curve.sample(alpha)
	sprite.scale.y = sprite.scale.x

func _on_triggered():
	visible = false
	sprite.position.y = _sprite_initial_position.y
