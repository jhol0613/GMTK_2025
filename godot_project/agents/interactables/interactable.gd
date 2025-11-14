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
	super._ready()

func execute_action(action : Enums.PlayerAction, beat: int, skip_animation := false) -> void:
	if not _interacted or repeatable:
		interaction_succeeded.emit()
		_interacted = true
		super.execute_action(action, beat, skip_animation)

func is_in_range(interact_position: Vector2i) -> bool:
	for relative_position in interactable_positions:
		if (grid_position + relative_position) == interact_position:
			return true
	return false
		
func reset():
	super.reset()
	_interacted = false
	sprite.play_with_signals(default_animation)
