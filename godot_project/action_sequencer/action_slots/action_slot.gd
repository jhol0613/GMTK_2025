extends Control

class_name ActionSlot

@export_subgroup("Slot Textures")
@export var active_texture: CompressedTexture2D
@export var inactive_texture: CompressedTexture2D
@export var action_textures: Dictionary[Enums.PlayerAction, CompressedTexture2D]

@export_subgroup("Light Colors")
@export var playing_light_color: Color
@export var thinking_light_color: Color
@export var space_available_light_color: Color

@export_subgroup("Flashing")
@export var flash_time := .2
@export var flash_reps := 30


@onready var texture_rect = $TextureRect
@onready var background_sprite = $Sprite2D
@onready var flash_timer = $Timer
@onready var place_block_emitter = $PlaceBlock
@onready var backlight = $Backlight
@onready var hover_emitter = $Hover

var action: Enums.PlayerAction = Enums.PlayerAction.NONE

# If active is false, cannot drag and drop
var is_active := true

# Controls whether a hovering mouse is registered
var ui_interaction_enabled := false

# What action to preview if hovered
var preview_action:= Enums.PlayerAction.NONE

var eraser_mode: bool = false

@onready var flashing_light_on := false: set = _update_flashing_light
@onready var hover_light_on := false: set = _update_hover_light
@onready var sequence_light_on := false: set = _update_sequence_light
@onready var flashing = false
@onready var _current_sequence_light_color := thinking_light_color

signal action_slot_clicked(ActionSlot)
signal stopped_flashing(ActionSlot)

func set_active(active: bool):
	is_active = active
	if is_active:
		background_sprite.texture = active_texture
	else:
		background_sprite.texture = inactive_texture
		ui_interaction_enabled = false

func _can_drop_data(_position, data):
	return data["type"] == "item" and data["quantity"] > 0 and is_active

func _drop_data(_position, data):
	set_action(data["action"])
	data["reference"].decrease_quantity()

func clear_slot():
	texture_rect.texture = null
	action = Enums.PlayerAction.NONE

func set_action(new_action: Enums.PlayerAction, silent = false):
	# in case the loaded solution contains a weird action, which WILL NOT HAPPEN
	if new_action not in action_textures.keys() and new_action != Enums.PlayerAction.NONE:
		return
	action = new_action
	texture_rect.texture = action_textures.get(action)
	hover_light_on = false
	if not silent:
		place_block_emitter.play()

func set_to_thinking_mode_color():
	_current_sequence_light_color = thinking_light_color

func set_to_playing_mode_color():
	_current_sequence_light_color = playing_light_color

func _update_flashing_light(new_state):
	flashing_light_on = new_state
	_update_light()

func _update_hover_light(new_state):
	if !hover_light_on and new_state:
		hover_emitter.play()
	hover_light_on = new_state
	_update_light()

func _update_sequence_light(new_state):
	sequence_light_on = new_state
	_update_light()

# Ensures that lights take on color/visibility in the proper priority order
func _update_light():
	# Priority is flashing light, hover light, sequence light
	if flashing_light_on:
		backlight.color = space_available_light_color
	elif hover_light_on:
		backlight.color = space_available_light_color
	elif sequence_light_on:
		backlight.color = _current_sequence_light_color
	backlight.visible = sequence_light_on or hover_light_on or flashing_light_on

func start_flashing():
	flashing = true
	flash_timer.start(flash_time)

func stop_flashing():
	flashing = false
	flash_timer.stop()
	flashing_light_on = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		#if eraser_mode:
			#if action != Enums.PlayerAction.NONE:
				#clear_slot()
				#accept_event()
				#return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_active and ui_interaction_enabled and action != preview_action:
				action_slot_clicked.emit(self)

func _on_mouse_entered() -> void:
	if ui_interaction_enabled and action != preview_action:
		hover_light_on = true
		texture_rect.texture = action_textures.get(preview_action)
		if flashing:
			stop_flashing()
			stopped_flashing.emit(self)

func _on_mouse_exited() -> void:
	hover_light_on = false
	if action == Enums.PlayerAction.NONE:
		texture_rect.texture = null
	else:
		texture_rect.texture = action_textures.get(action)

func _on_flash_timer_timeout() -> void:
	if not flashing:
		return
	flashing_light_on = !flashing_light_on
	flash_timer.start(flash_time)

func set_eraser_mode(on: bool) -> void:
	eraser_mode = on
