extends Node

#region Exports
@export_category("UI Scenes")

@export_subgroup("Action items")
@export var move_up_scene: PackedScene
@export var move_right_scene: PackedScene
@export var move_down_scene: PackedScene
@export var move_left_scene: PackedScene

@export_subgroup("Slots")
@export var action_slot_scene: PackedScene

@export_category("UI Containers")

@export var items_container: Container
@export var slots_container: Container

@export_category("Actions")

@export_range(0, 32) var available_slots: int = 0
@export var available_actions: Array[Action] = []
@export var action_quantities: Array[int] = []


#endregion

#region Type declarations

enum SequencingState {
	SEQUENCING,
	RUNNING,
	FINISHED,
}

enum Action {
	MOVE_UP,
	MOVE_RIGHT,
	MOVE_DOWN,
	MOVE_LEFT,
	# TODO: add more actions to the sequencer
}

# container class to store an instance to the slot and its corresponding data
class ActionItemData:
	var node: ActionItem
	var quantity: int
	var action: Action
	
	func _init(_node: ActionItem, _quantity: int, _action: Action) -> void:
		self.node = _node
		self.quantity = _quantity
		self.action = _action

#endregion

#region Internal state

var current_state := SequencingState.SEQUENCING
var current_action := 0
var action_list := []

var initialized_slots: Array[ActionSlot] = []
var initialized_items: Array[ActionItemData] = []

# null if no item is selected
var dragged_item: ActionItem = null

#endregion

#region Signals
signal move_up
signal move_right
signal move_down
signal move_left
# TODO: add signals for each new action
#endregion

func _ready() -> void:
	# instantiate slots and items, add them to their respective containers and
	# reference arrays
	for i in range(available_slots):
		initialized_slots.append(action_slot_scene.instantiate())
		slots_container.add_child(initialized_slots.back())
	for i in range(available_actions.size()):
		var action_scene: PackedScene
		match available_actions[i]:
			Action.MOVE_UP:
				action_scene = move_up_scene
			Action.MOVE_RIGHT:
				action_scene = move_right_scene
			Action.MOVE_DOWN:
				action_scene = move_down_scene
			Action.MOVE_LEFT:
				action_scene = move_left_scene
		initialized_items.append(action_scene.instantiate())
		items_container.add_child(initialized_items.back())

func play():
	if current_state != SequencingState.SEQUENCING:
		push_warning("Sequencer is not running, skipping advance()")
		return
	# TODO: add a callback to enable the UI
	current_state = SequencingState.RUNNING

# make one step in the simulation
func advance():
	if current_state != SequencingState.RUNNING:
		return

	if action_list.size() <= current_action or current_action < 0:
		push_error("Sequencer has broken state!")
		return

	if action_list.size() - 1 == current_action:
		current_state = SequencingState.FINISHED
		return

	match action_list[current_action]:
		Action.MOVE_UP:
			move_up.emit()
		Action.MOVE_RIGHT:
			move_right.emit()
		Action.MOVE_DOWN:
			move_down.emit()
		Action.MOVE_LEFT:
			move_left.emit()
		_:
			push_error("Sequencer encountered unknown action!")

	current_action += 1
