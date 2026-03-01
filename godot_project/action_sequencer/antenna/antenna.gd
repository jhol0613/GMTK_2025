@tool

extends Control

class_name Antenna

##Use the "RAW" tab in color picker to select modulate values >1 (to make sprite lighter)
@export var mouse_hover_modulate := Color(1.5, 1.5, 1.5)
@export var sprite : AnimatedSprite2DSignals
@export var buttton : Button

@onready var _parent = get_parent()
var _original_parent_modulate

var programs : Array[TerminalProgram]

signal selected(programs: Antenna)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("antennas")
	for child in get_children():
		if child is TerminalProgram:
			programs.append(child)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _parent is CanvasItem:
		_original_parent_modulate = _parent.modulate

func _on_mouse_entered():
	sprite.modulate = mouse_hover_modulate
	if _parent is CanvasItem:
		_parent.modulate = mouse_hover_modulate

func _on_mouse_exited():
	sprite.modulate = Color(1,1,1,1)
	if _parent is CanvasItem:
		_parent.modulate = _original_parent_modulate

func _on_clicked() -> void:
	selected.emit(self)

func get_sprite_global_position():
	return sprite.global_position

func set_active_animation(new_active: bool):
	if new_active:
		sprite.play_with_signals("active")
	else:
		sprite.play_with_signals("inactive")



# Ensure terminal program is configured as a child node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	for child in get_children():
		if child is TerminalProgram:
			return warnings
	warnings.append("Antenna must have at least one terminal program as a direct child in order to have any functionality")
	return warnings
