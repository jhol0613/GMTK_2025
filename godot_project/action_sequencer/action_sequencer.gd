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

@export_category("Actions")

@export_range(0, 32) var available_slots: int = 0
@export var available_actions: Array[Enums.PlayerAction] = []
@export var action_quantities: Array[int] = []

@export var total_slots := 8

@export_category("Sequencer")
## The amount of time to wait to start sequencing actions after play button pushed
@export var play_action_delay := 0.0


#endregion

#region Type declarations

@onready var _action_items = $ActionItems
@onready var _play_button = $TextureRect/PlayButton
@onready var _play_light1 = $TextureRect/PlayButton/PlayLight1
@onready var _play_light2 = $TextureRect/PlayButton/PlayLight2

signal play_started
signal replay_pressed

enum SequencingState {
	SEQUENCING,
	RUNNING,
	FINISHED,
}

#endregion

#region Internal state

var current_state := SequencingState.SEQUENCING
var current_action := 0

# ActionSlot
var initialized_slots := []
# ActionItemData
var initialized_items := []

var active_action_item : ActionItem

#endregion

#region Signals

signal perform_action(type: Enums.PlayerAction)

#endregion


func _ready() -> void:
	# Connect to beat signal
	AudioManager.music_bar.connect(_on_advance)
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	
	# instantiate slots and items, add them to their respective containers and
	# reference arrays
	for i in range(available_slots):
		initialized_slots.append(action_slot_scene.instantiate())
		slots_container.add_child(initialized_slots.back())
		initialized_slots.back().connect("action_slot_clicked", _on_action_slot_clicked)
	for i in range(total_slots - available_slots):
		var new_slot = action_slot_scene.instantiate()
		initialized_slots.append(new_slot)
		slots_container.add_child(initialized_slots.back())
		new_slot.set_active(false)
		
	for i in range(available_actions.size()):

		initialized_items.append(action_item_scene.instantiate())
		initialized_items.back().action = available_actions[i]
		initialized_items.back().quantity = action_quantities[i]

		items_container.add_child(initialized_items.back())
		initialized_items.back().set_action(available_actions[i]) # set the action icon once added to the tree
		initialized_items.back().connect("action_item_clicked", _on_action_item_clicked)
	


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

	if initialized_slots.size() < current_action or current_action < 0:
		push_error("Sequencer has broken state!")
		print(initialized_slots.size(), " ", current_action)
		return

	if available_slots == current_action:
		current_action = 0
		
	initialized_slots[current_action].set_sequencer_light_on(true)
	if current_action > 0:
		initialized_slots[current_action-1].set_sequencer_light_on(false)
	else:
		initialized_slots[available_slots-1].set_sequencer_light_on(false)
	perform_action.emit(initialized_slots[current_action].action)
	current_action += 1

func _reset_actions():
	for i in range(available_actions.size()):
		initialized_items[i].quantity = action_quantities[i]
	
	for i in range(available_slots):
		initialized_slots[i].clear_slot()
		

func set_action_icons_hidden(should_hide: bool):
	_action_items.visible = !should_hide
	
func stop_sequencer():
	current_state = SequencingState.FINISHED

## Does the same thing as hitting the replay button
func push_replay_button():
	_on_replay_button_pressed()

#region Signal connections

func _on_advance() -> void:
	if current_state == SequencingState.RUNNING:
		advance()


func _on_play_button_pressed() -> void:
	_play_button.disabled = true
	_play_light1.visible = true
	_play_light2.visible = true
	play()


func _on_replay_button_pressed() -> void:
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	_reset_actions()
	_play_button.disabled = false
	_play_light1.visible = false
	_play_light2.visible = false
	replay_pressed.emit()
	current_state = SequencingState.SEQUENCING
	
func _on_action_item_clicked(new_action_item: ActionItem):
	active_action_item = new_action_item
	for item in initialized_items:
		if item != active_action_item:
			item.deselect()
			
	for i in range(available_slots):
		initialized_slots[i].ui_interaction_enabled = true
		
func _on_action_slot_clicked(clicked_slot : ActionSlot):
	if active_action_item != null:
		clicked_slot.set_action(active_action_item.action)

#endregion
