extends Control

class_name ActionItem

var _dragging := false
var _offset: Vector2
var _initial_position: Vector2

const initial_z_index := 0
const bumped_z_index := 1

# in ActionSequencer, we determine which action is taken by comparing the instances
signal drag_start(instance: ActionItem)
signal drag_stop(instance: ActionItem)

func _physics_process(_delta):
	if _dragging:
		self.global_position = get_global_mouse_position() + _offset

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _dragging == event.is_pressed():
		return

	if event.is_pressed():
		_offset = global_position - get_global_mouse_position()
		_initial_position = global_position
		z_index = bumped_z_index
		drag_start.emit(self)
	else:
		set_global_position(_initial_position)
		z_index = initial_z_index
		drag_stop.emit(self)
	_dragging = event.is_pressed()
	accept_event()
