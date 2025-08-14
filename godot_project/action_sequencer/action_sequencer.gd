extends Control

class_name ActionSequencer

#region Exports
@export_category("UI Scenes")

@export_subgroup("Action items")
@export var action_item_scene : PackedScene

@export_subgroup("Slots")
@export var action_slot_scene: PackedScene

@export_category("UI Containers")

@export var items_container: Container
@export var slots_container: Container

@export_category("Sequencer Config")
## The amount of time to wait to start sequencing actions after play button pushed
@export var play_action_delay := 0.0
@export var tutorial_mode := true
@export_subgroup("Advanced")
@export var default_action_quantities: Array[int]
@export var total_slots := 8
@export var max_actions := 8

#endregion

#region Type declarations

@onready var _action_items = $TextureRect/ActionItems
@onready var _play_button = $TextureRect/PlayButton
@onready var _play_light1 = $TextureRect/PlayButton/PlayLight1
@onready var _play_light2 = $TextureRect/PlayButton/PlayLight2
@onready var _tutorial_arrow = $TextureRect/TutorialArrow
@onready var play_button_hover_emitter = $TextureRect/PlayButton/PlayButtonHover
@onready var play_button_press_emitter = $TextureRect/PlayButton/PlayButtonPress
@onready var replay_button_press_emitter = $TextureRect/ReplayButton/ReplayButtonPress

signal play_started
signal replay_pressed

enum SequencingState {
	SEQUENCING,
	RUNNING,
	FINISHED,
}

#endregion

#region Internal state
# Sequencer settings from level data
var _available_slots: int = 0
var _available_actions: Array[Enums.PlayerAction] = []
var _action_quantities: Array[int] = []

var current_state := SequencingState.SEQUENCING
var current_action := 0

# ActionSlot
var _initialized_slots := []
# ActionItemData
var _initialized_items := []

var _active_action_item : ActionItem

#endregion

#region Signals

signal perform_action(type: Enums.PlayerAction)

#endregion


func _ready() -> void:
	# Connect to beat signal
	AudioManager.music_bar.connect(_on_advance)
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)


func play():
	if current_state != SequencingState.SEQUENCING:
		push_warning("Sequencer is not running, skipping advance()")
		return
	# TODO: add a callback to enable the UI
	AudioManager.set_music_mode(Enums.MusicMode.RUNNING)
	_action_items.visible = false
	play_started.emit()

	# Wait for specified delay (for external animations) to start sequencing actions
	await get_tree().create_timer(play_action_delay).timeout
	current_state = SequencingState.RUNNING
	current_action = 0


# make one step in the simulation
func advance():
	if current_state != SequencingState.RUNNING:
		return

	if _initialized_slots.size() < current_action or current_action < 0:
		push_error("Sequencer has broken state!")
		print(_initialized_slots.size(), " ", current_action)
		return

	if _available_slots == current_action:
		current_action = 0

	_initialized_slots[current_action].set_sequencer_light_on(true)
	if current_action > 0:
		_initialized_slots[current_action-1].set_sequencer_light_on(false)
	else:
		_initialized_slots[_available_slots-1].set_sequencer_light_on(false)
	perform_action.emit(_initialized_slots[current_action].action)
	current_action += 1

# should be called when a new level wants to update sequencer parameters
func update_sequencer_data(new_available_slots: int, new_available_actions: Array[Enums.PlayerAction], new_action_quantities := default_action_quantities):

	# Update state variables
	_available_slots = new_available_slots
	_available_actions = new_available_actions
	_action_quantities = new_action_quantities

	# clear out slots and items
	_initialized_slots.clear()
	for slot in slots_container.get_children():
		slot.queue_free()
	_initialized_items.clear()
	for item in items_container.get_children():
		item.queue_free()

	# instantiate slots and add them to their respective containers and reference arrays
	for i in range(_available_slots):
		_initialized_slots.append(action_slot_scene.instantiate())
		slots_container.add_child(_initialized_slots.back())
		_initialized_slots.back().connect("action_slot_clicked", _on_action_slot_clicked)
		if tutorial_mode:
			_initialized_slots.back().connect("stopped_flashing", _on_one_slot_stopped_flashing)
	# fill slots above the available limit with inactive slots
	for i in range(total_slots - _available_slots):
		var new_slot = action_slot_scene.instantiate()
		_initialized_slots.append(new_slot)
		slots_container.add_child(_initialized_slots.back())
		new_slot.set_active(false)

	# instantiate items and add them to their respective containers and reference arrays
	for i in range(_available_actions.size()):
		_initialized_items.append(action_item_scene.instantiate())
		_initialized_items.back().action = _available_actions[i]
		_initialized_items.back().quantity = _action_quantities[i]
		items_container.add_child(_initialized_items.back())
		_initialized_items.back().set_action(_available_actions[i]) # set the action icon once added to the tree
		_initialized_items.back().connect("action_item_clicked", _on_action_item_clicked)
		if tutorial_mode:
			_initialized_items[i].flash()
			_initialized_items.back().connect("stopped_flashing", _on_one_action_item_stopped_flashing)
	# Add NONE actions to fill the action tray to preserve layout
	for i in range(max_actions - _available_actions.size()):
		_initialized_items.append(action_item_scene.instantiate())
		_initialized_items.back().action = Enums.PlayerAction.NONE
		items_container.add_child(_initialized_items.back())

	# Reset the sequencer
	_clear_action_slots()
	_enter_thinking_mode()

func _enter_thinking_mode():
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	current_state = SequencingState.SEQUENCING
	_turn_off_sequence_light()
	_play_button.disabled = false
	_play_light1.visible = false
	_play_light2.visible = false

func set_action_icons_hidden(should_hide: bool):
	_action_items.visible = !should_hide

func stop_sequencer():
	current_state = SequencingState.FINISHED

## Does the same thing as hitting the replay button
func push_replay_button():
	_on_replay_button_pressed()

# Clears out all slots and resets action quanitities
func _clear_action_slots():
	for i in range(_available_actions.size()):
		_initialized_items[i].quantity = _action_quantities[i]
	for i in range(_available_slots):
		_initialized_slots[i].clear_slot()

func _turn_off_sequence_light():
	for slot in _initialized_slots:
		slot.set_sequencer_light_on(false)

#region Signal connections

func _on_advance() -> void:
	if current_state == SequencingState.RUNNING:
		advance()


func _on_play_button_pressed() -> void:
	if not tutorial_mode:
		_play_button.disabled = true
		_play_light1.visible = true
		_play_light2.visible = true
		play_button_press_emitter.play()
		play()


func _on_replay_button_pressed() -> void:
	_enter_thinking_mode()
	replay_pressed.emit()
	replay_button_press_emitter.play()

func _on_action_item_clicked(new_action_item: ActionItem):
	if tutorial_mode:
		_tutorial_arrow.visible = true
	_active_action_item = new_action_item
	for item in _initialized_items:
		if item != _active_action_item:
			item.deselect()

	for i in range(_available_slots):
		_initialized_slots[i].ui_interaction_enabled = true
		_initialized_slots[i].preview_action = _active_action_item.action
		if tutorial_mode:
			_initialized_slots[i].flash()

func _on_action_slot_clicked(clicked_slot : ActionSlot):
	if _active_action_item != null:
		clicked_slot.set_action(_active_action_item.action)

func _on_one_slot_stopped_flashing(_stopped_slot: ActionSlot):
	for i in range(_available_slots):
		_initialized_slots[i].stop_flashing()
	tutorial_mode = false
	_tutorial_arrow.visible = false

func _on_one_action_item_stopped_flashing(_stopped_slot: ActionItem):
	for item in _initialized_items:
		item.stop_flashing()

func _on_play_button_mouse_entered() -> void:
	play_button_hover_emitter.play()

func _on_replay_button_mouse_entered() -> void:
	play_button_hover_emitter.play()

#endregion
