@tool
extends Node2D

@export var target_positions: Dictionary[Sprite2D, Vector2]
@export var animation_player: AnimationPlayer
@export var transform_animation := "startransform"
@export var transform_time := 3.0

@export_tool_button("Save Star Target Positions") var _save_target_positions_button = _save_target_positions


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = 3.0 / transform_time
	
	
func _save_target_positions():
	print("hello")
	for star in target_positions.keys():
		target_positions[star] = star.position
	notify_property_list_changed()

func transform_stars():
	animation_player.play(transform_animation)
	var tween = create_tween()
	tween.set_parallel(true)
	for star in target_positions.keys():
		tween.tween_property(star, "position", target_positions.get(star), transform_time)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
