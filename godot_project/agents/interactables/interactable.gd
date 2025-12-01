extends Agent

class_name Interactable

signal interaction_succeeded

## Grid locations (relative to interactable location) from which you can interact
@export var interactable_positions: Array[Vector2i] = \
	[
		Vector2i.ZERO,
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
@export var repeatable := false
## On successful interaction, what animation should player do?
@export var player_animation_on_success : String
	
var _interacted = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")
	super._ready()

## True if action will successfully execute if execute_action is called
func can_interact():
	return not _interacted or repeatable

func execute_action(action : Enums.PlayerAction, beat: int, skip_animation := false) -> void:
	if can_interact():
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
