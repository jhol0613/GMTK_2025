extends Agent

class_name Interactable

signal interaction_succeeded

##Grid locations (relative to interactable location) from which you can interact
@export var interactable_positions: Array[Vector2i] = \
	[
		Vector2i.ZERO,
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
@export var repeatable := false
	
var _interacted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")
	AudioManager.bpm_changed.connect(on_bpm_changed)
	on_bpm_changed(0.0) # just uses the bpm from the audio manager anyway so 0.0 doesn't matter

func interact(action: Enums.PlayerAction):
	# reset animations to match bpm in case it has changed
	for animation_name in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.set_animation_speed(animation_name, AudioManager.get_fps_from_bpm())
	if not _interacted or repeatable:
		interaction_succeeded.emit()
		_interacted = true

func is_in_range(interact_position: Vector2i) -> bool:
	for relative_position in interactable_positions:
		if (grid_position + relative_position) == interact_position:
			return true
	return false
	
func on_bpm_changed(new_bpm: float):
	for animation_name in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.set_animation_speed(animation_name, AudioManager.get_fps_from_bpm())
