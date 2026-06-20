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
##Highlight shader can't be used on animated sprite, so it uses this as a stand-in for its shape
@export var highlight_sprites: Array[Sprite2D]
var highlight_shader

var _interacted = false

signal updated_position(this_interactable: Interactable, new_global_position: Vector2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")
	_on_flip_horizontal(flip_horizontal)
	highlight_shader = ShaderMaterial.new()
	highlight_shader.shader = load(Enums.Shaders.HIGHLIGHT_GLINT)
	highlight_shader.set_shader_parameter("offset", AudioManager.beat_time_seconds * 16)
	for highlight_sprite in highlight_sprites:
		highlight_sprite.material = highlight_shader
	super._ready()

#Override in children if additional flip functionality desired (e.g. cat coffee spill spawn location)
func _on_flip_horizontal(new_flipped_status):
	if not sprite:
		return
	flip_horizontal = new_flipped_status
	sprite.flip_h = new_flipped_status

## True if action will successfully execute if execute_action is called
func can_interact():
	return not _interacted or repeatable

func execute_action(action : Enums.PlayerAction, beat: int, skip_animation := false, instant = false) -> void:
	if can_interact():
		interaction_succeeded.emit()
		_interacted = true
		for highlight_sprite in highlight_sprites:
			highlight_sprite.visible = can_interact()
		super.execute_action(action, beat, skip_animation)

func is_in_range(interact_position: Vector2i) -> bool:
	for relative_position in interactable_positions:
		if (grid_position + relative_position) == interact_position:
			return true
	return false

##For interactables that trigger a different animation based on player's relative position, override this function
##to set the appropriate animation (e.g. set cat petting animation in appropriate direction)
func update_player_animation_based_on_position(player_grid_position: Vector2i):
	pass

func reset():
	super.reset()
	_interacted = false
	for highlight_sprite in highlight_sprites:
		highlight_sprite.visible = can_interact()
	sprite.play_with_signals(default_animation)
