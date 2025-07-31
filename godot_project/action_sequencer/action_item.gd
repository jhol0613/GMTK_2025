extends Area2D

class_name ActionItem

var _dragging := false

# in ActionSequencer, we determine which action is taken by comparing the instances
signal drag_start(instance: ActionItem)
signal drag_stop(instance: ActionItem)

func _physics_process(delta):
	if _dragging:
		self.global_position = get_global_mouse_position()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == 1:
		if _dragging != event.pressed:
			if event.pressed:
				drag_start.emit(self)
			else:
				drag_stop.emit(self)
		_dragging = event.pressed
		
func _input(event):
	if event is InputEventMouseButton and event.button_index == 1 and _dragging:
		_dragging = false
		
