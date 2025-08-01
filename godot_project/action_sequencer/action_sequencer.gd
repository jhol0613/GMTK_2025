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
		
	initialized_slots[current_action].set_light_on(true)
	if current_action > 0:
		initialized_slots[current_action-1].set_light_on(false)
	else:
		initialized_slots[available_slots-1].set_light_on(false)
	perform_action.emit(initialized_slots[current_action].action)
	current_action += 1

func _reset_actions():
	for i in range(available_actions.size()):
		initialized_items[i].quantity = action_quantities[i]
	
	for i in range(available_slots):
		initialized_slots[i].clear_slot()
		

#region Signal connections

func _on_advance() -> void:
	if current_state == SequencingState.RUNNING:
		advance()


func _on_play_button_pressed() -> void:
	play()


func _on_replay_button_pressed() -> void:
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	_action_items.visible = true
	_reset_actions()
	replay_pressed.emit()
	current_state = SequencingState.SEQUENCING

#endregion
