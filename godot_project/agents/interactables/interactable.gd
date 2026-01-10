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
@export var follow_on_animation_on_success := "idle_down"
##Note that a horizontal flip won't appear in the editor
@export var flip_horizontal := false: set = _on_flip_horizontal
	
var _interacted = false

signal updated_position(this_interactable: Interactable, new_global_position: Vector2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")
	_on_flip_horizontal(flip_horizontal)
	super._ready()

#Override in children if additional flip functionality desired (e.g. cat coffee spill spawn location)
func _on_flip_horizontal(new_flipped_status):
	flip_horizontal = new_flipped_status
	sprite.flip_h = new_flipped_status

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
