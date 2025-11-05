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
@export var default_animation_name := "default"
	
var _interacted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")

func interact(action: Enums.PlayerAction):
	if not _interacted or repeatable:
		interaction_succeeded.emit()
		_interacted = true

func is_in_range(interact_position: Vector2i) -> bool:
	for relative_position in interactable_positions:
		if (grid_position + relative_position) == interact_position:
			return true
	return false
		
func reset():
	super.reset()
	_interacted = false
	sprite.play_with_signals(default_animation_name)
