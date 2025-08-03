extends Control

class_name ActionSlot

@export var active_texture: CompressedTexture2D
@export var inactive_texture: CompressedTexture2D

@export var action_textures: Dictionary[Enums.PlayerAction, CompressedTexture2D]

@export var sequencer_light_color: Color
@export var space_available_light_color: Color
@export var flash_time := .2
@export var flash_reps := 30

@onready var texture_rect = $TextureRect
@onready var background_sprite = $Sprite2D
@onready var flash_timer = $Timer

var action: Enums.PlayerAction = Enums.PlayerAction.NONE

var flashing = false

# If active is false, cannot drag and drop
var is_active := true

# Controls whether a hovering mouse is registered
var ui_interaction_enabled := false

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
	
func set_sequencer_light_on(on: bool):
	if on:
		$Backlight.color = sequencer_light_color
	$Backlight.visible = on
	
func set_space_available_light_on(on: bool):
	if on:
		$Backlight.color = space_available_light_color
	$Backlight.visible = on
	
func set_action(new_action: Enums.PlayerAction):
	action = new_action
	texture_rect.texture = action_textures.get(action)
	set_space_available_light_on(false)

func flash():
	print("flash")
	flashing = true
	flash_timer.start(flash_time)
		
func stop_flashing():
	set_space_available_light_on(false)
	flashing = false
	flash_timer.stop()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_active:
				action_slot_clicked.emit(self)


func _on_mouse_entered() -> void:
	if ui_interaction_enabled:
		if flashing:
			stop_flashing()
			stopped_flashing.emit(self)
		set_space_available_light_on(true)

func _on_mouse_exited() -> void:
	set_space_available_light_on(false)


func _on_flash_timer_timeout() -> void:
	if not flashing:
		return
	if $Backlight.visible:
		set_space_available_light_on(false)
	else:
		set_space_available_light_on(true)
	flash_timer.start(flash_time)
