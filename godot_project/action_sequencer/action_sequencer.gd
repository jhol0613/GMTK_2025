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

@export_category("Animation")
##Amount of time that screen flashes when new antenna is selected
@export var _screen_flash_time := 0.20

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

@onready var _music_slider: VSlider = $TextureRect/MusicSlider
@onready var music_slider_click_emitter = $TextureRect/MusicSlider/MusicSliderClick
@onready var music_slider_release_emitter = $TextureRect/MusicSlider/MusicSliderRelease

@onready var _sfx_slider:   VSlider = $TextureRect/SfxSlider
@onready var sfx_slider_click_emitter = $TextureRect/SfxSlider/SfxSliderClick
@onready var sfx_slider_release_emitter = $TextureRect/SfxSlider/SfxSliderRelease

@onready var _speed_btn: TextureButton = $TextureRect/SpeedControl
@onready var speed_btn_emitter = $TextureRect/SpeedControl/Switch

@onready var _redo_btn = $TextureRect/RedoButton
@onready var redo_btn_hover_emitter = $TextureRect/RedoButton/RedoButtonHover
@onready var redo_btn_press_emitter = $TextureRect/RedoButton/RedoButtonPress

@onready var _eraser_btn= $TextureRect/EraserButton
@onready var eraser_btn_hover_emitter = $TextureRect/EraserButton/EraserButtonHover
@onready var eraser_btn_press_emitter = $TextureRect/EraserButton/EraserButtonPress
var _eraser_mode := false

@onready var _screen = $TextureRect/ScreenOff/ScreenOn
@onready var _conductor_spawn_text = $TextureRect/ScreenOff/ScreenOn/ConductorSpawnCountdown
@onready var _antenna = $TextureRect/Antenna
@onready var antenna_tip = $TextureRect/Antenna/AntennaTip
@onready var _antenna_deployed = false
var conductor_spawned_countdown : set = _on_conductor_countdown_changed

const P_MUSIC := "Music_Vol"
const P_SFX   := "SFX_Vol"

const ERASER_CURSOR := preload("res://action_sequencer/sequencer_visuals/eraser_button/EraserMouse.png")
const ERASER_HOTSPOT := Vector2(6, 14)

enum SequencingState {
	SEQUENCING,
	RUNNING,
	FINISHED,
}

@onready var buttons_enabled = true

#endregion

#region Internal state
# Sequencer settings from level data
var _available_slots: int = 0
var _available_actions: Array[Enums.PlayerAction] = []
var _action_quantities: Array[int] = []

var current_state := SequencingState.SEQUENCING
var current_action := 0

# ActionSlot
var _initialized_slots := [ActionSlot]
# ActionItemData
var _initialized_items := [ActionItem]

var _active_action_item : ActionItem

# Prevents play mode from being triggered if replay is pressed while waiting for the beat
var _lock_thinking_mode := true

#endregion

#region Signals

signal perform_action(type: Enums.PlayerAction)
signal perform_thinking_action
signal play_started
signal replay_pressed

#endregion


func _ready() -> void:
	# Connect to beat signal
	AudioManager.music_bar.connect(_on_advance)
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)

	_music_slider.value = FmodServer.get_global_parameter_by_name(P_MUSIC)
	_sfx_slider.value   = FmodServer.get_global_parameter_by_name(P_SFX)

	_music_slider.connect("value_changed", Callable(self, "_on_music_slider_changed"))
	_sfx_slider.connect("value_changed", Callable(self, "_on_sfx_slider_changed"))

	_speed_control_ready()

	_setup_eraser_button()


func play():
	if current_state != SequencingState.SEQUENCING:
		push_warning("Sequencer is not running, skipping advance()")
		return

	AudioManager.set_music_mode(Enums.MusicMode.RUNNING)
	_action_items.visible = false

	# Wait for specified delay (for external animations) to start sequencing actions
	#await get_tree().create_timer(play_action_delay).timeout

	play_started.emit()

	current_action = 0
	_turn_off_sequencer_lights()
	for i in range(_available_slots):
		_initialized_slots[i].set_to_playing_mode_color()
		_initialized_slots[i].ui_interaction_enabled = false
	current_state = SequencingState.RUNNING



# make one step in the simulation
func advance():

	if _initialized_slots.size() < current_action or current_action < 0:
		push_error("Sequencer has broken state!")
		print(_initialized_slots.size(), " ", current_action)
		return

	if _available_slots == current_action:
		current_action = 0

	# Update lights while sequencing
	_initialized_slots[current_action].sequence_light_on = true
	if current_action > 0:
		_initialized_slots[current_action-1].sequence_light_on = false#   set_light_status(Enums.LightStatus.OFF, true, should_set_default_only)
	else:
		_initialized_slots[_available_slots-1].sequence_light_on = false#  set_light_status(Enums.LightStatus.OFF, true, should_set_default_only)

	# Sequencer stays running in thinking mode, but emits different type of signal for level manager to interpret
	if current_state == SequencingState.RUNNING:
		perform_action.emit(_initialized_slots[current_action].action)
	elif current_state == SequencingState.SEQUENCING:
		perform_thinking_action.emit()

	current_action += 1

# should be called when a new level wants to update sequencer parameters
func update_sequencer_data(new_available_slots: int, new_available_actions: Array[Enums.PlayerAction],
	new_action_quantities := default_action_quantities):

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

func set_current_sequence(sequence: Array[Enums.PlayerAction]) -> void:
	for slot in _initialized_slots:
		slot.set_action(Enums.PlayerAction.NONE, true)

	for i in range(min(_available_slots, sequence.size())):
		var slot = _initialized_slots[i]
		slot.set_action(sequence[i], true)

func get_current_sequence() -> Array[Enums.PlayerAction]:
	var sequence: Array[Enums.PlayerAction] = []

	for i in range(_available_slots):
		sequence.append(_initialized_slots[i].action)

	return sequence

func _enter_thinking_mode():
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)
	current_state = SequencingState.SEQUENCING
	_turn_off_sequencer_lights()
	_play_button.disabled = false
	_play_light1.visible = false
	_play_light2.visible = false
	for i in range(_available_slots):
		_initialized_slots[i].ui_interaction_enabled = true
		_initialized_slots[i].set_to_thinking_mode_color()
	_redo_btn.disabled = false
	_eraser_btn.disabled = false

func set_action_icons_hidden(should_hide: bool):
	_action_items.visible = !should_hide

func stop_sequencer():
	current_state = SequencingState.FINISHED

## Does the same thing as hitting the replay button
func push_replay_button():
	_on_replay_button_pressed()

func connect_antenna_to_screen(terminal_program: TerminalProgram):
	for child in _screen.get_children():
		child.queue_free()
	if terminal_program.packed_sequencer_control_scene:
		_screen.visible = true
		var control_screen = terminal_program.packed_sequencer_control_scene.instantiate()
		terminal_program.initialize_screen(control_screen)
		_screen.add_child(control_screen)
	antenna_tip.emitting = true
	_screen.modulate = Color(5,5,5)
	await get_tree().create_timer(_screen_flash_time).timeout
	_screen.modulate = Color(1,1,1)


func deploy_antenna():
	if not _antenna_deployed:
		_antenna.play()
	_antenna_deployed = true

# Clears out all slots and resets action quanitities
func _clear_action_slots():
	for i in range(_available_actions.size()):
		_initialized_items[i].quantity = _action_quantities[i]
	for i in range(_available_slots):
		_initialized_slots[i].clear_slot()

func _turn_off_sequencer_lights():
	for i in range(_available_slots):
		_initialized_slots[i].sequence_light_on = false

func _on_conductor_countdown_changed(new_value: int):
	if not _conductor_spawn_text:
		return
	if new_value == 0:
		_conductor_spawn_text.visible = false
	else:
		_conductor_spawn_text.visible = true
	_conductor_spawn_text.text = str(new_value)

#region Signal connections

func _on_advance() -> void:
	if current_state != SequencingState.FINISHED:
		advance()


func _on_play_button_pressed() -> void:
	if not buttons_enabled:
		return
	if not tutorial_mode:
		_play_button.disabled = true
		_play_light1.visible = true
		_play_light2.visible = true
		play_button_press_emitter.play()
		play()
	_eraser_btn.disabled = true
	_redo_btn.disabled = true
	_exit_erase_mode()


func _on_replay_button_pressed() -> void:
	current_action = 0
	_lock_thinking_mode = true
	if buttons_enabled:
		_enter_thinking_mode()
		replay_pressed.emit()
		replay_button_press_emitter.play()

func _on_action_item_clicked(new_action_item: ActionItem):
	if tutorial_mode:
		_tutorial_arrow.visible = true

	if _active_action_item == new_action_item:
		_enter_erase_mode()
	else:
		_exit_erase_mode()
		_active_action_item = new_action_item
		for item in _initialized_items:
			if item != _active_action_item:
				item.deselect()

	_update_slot_action_previews()

func _on_action_slot_clicked(clicked_slot : ActionSlot):
	if _active_action_item != null:
		clicked_slot.set_action(_active_action_item.action)
	else:
		print("active action item is null")
		clicked_slot.set_action(Enums.PlayerAction.NONE)

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

func _on_music_slider_changed(value):
	FmodServer.set_global_parameter_by_name(P_MUSIC, value)

func _on_music_slider_drag_started() -> void:
	music_slider_click_emitter.play()

func _on_music_slider_drag_ended(_value_changed: bool) -> void:
	music_slider_release_emitter.play()

func _on_sfx_slider_drag_started() -> void:
	sfx_slider_click_emitter.play()

func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	sfx_slider_release_emitter.play()

func _on_sfx_slider_changed(value):
	FmodServer.set_global_parameter_by_name(P_SFX, value)

func _speed_control_ready() -> void:
	_speed_btn.toggle_mode = true
	_speed_btn.button_pressed = false
	AudioManager.update_time_multiplier(Enums.TimeMultiplier.SINGLE)
	_speed_btn.toggled.connect(_on_speed_toggled)

func _on_speed_toggled(pressed: bool) -> void:
	speed_btn_emitter.play()
	if _speed_btn.button_pressed:
		AudioManager.update_time_multiplier(Enums.TimeMultiplier.DOUBLE)
	else:
		AudioManager.update_time_multiplier(Enums.TimeMultiplier.SINGLE)

func _on_redo_button_mouse_entered() -> void:
	if not _redo_btn.disabled:
		redo_btn_hover_emitter.play()

func _on_redo_button_pressed() -> void:
	_exit_erase_mode()
	redo_btn_press_emitter.play()
	_clear_action_slots()

func _setup_eraser_button() -> void:
	_eraser_btn.toggle_mode = true
	_eraser_btn.button_pressed = false
	if _eraser_btn.toggled.is_connected(_on_eraser_toggled):
		_eraser_btn.toggled.disconnect(_on_eraser_toggled)
	_eraser_btn.toggled.connect(_on_eraser_toggled)

func _on_eraser_button_mouse_entered() -> void:
	if not _eraser_btn.disabled:
		eraser_btn_hover_emitter.play()

func _on_eraser_toggled(pressed: bool) -> void:
	if current_state == SequencingState.SEQUENCING:
		_eraser_mode = pressed
		if pressed:
			_enter_erase_mode()
			_update_slot_action_previews()
		else:
			_exit_erase_mode()
	#else:
		#_eraser_btn.pressed

## Deselect all action items, set current action to NONE, and set eraser cursor
func _enter_erase_mode():
	Input.set_custom_mouse_cursor(ERASER_CURSOR, Input.CURSOR_ARROW, ERASER_HOTSPOT)
	_eraser_btn.button_pressed = true
	_active_action_item = null
	for item in _initialized_items:
		item.deselect()

func _exit_erase_mode():
	Input.set_custom_mouse_cursor(null)
	_setup_eraser_button()

## Iterate through action slots and make sure preview is set to current action (or NONE if in erase mode)
func _update_slot_action_previews():
	for i in range(_available_slots):
		_initialized_slots[i].ui_interaction_enabled = true
		if _active_action_item == null:
			_initialized_slots[i].preview_action = Enums.PlayerAction.NONE
		else:
			_initialized_slots[i].preview_action = _active_action_item.action

		if tutorial_mode:
			_initialized_slots[i].start_flashing()

#endregion
