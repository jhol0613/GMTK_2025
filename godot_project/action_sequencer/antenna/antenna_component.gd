extends AnimatedSprite2DSignals

class_name AntennaComponent

##This will be highlighted when hovered
@export var highlighted_nodes : Array[Node]
##When mouse hovers over these buttons, highlight will be applied
@export var detection_areas : Array[Button]
##Modulate color when mouse hovered
@export var mouse_hover_modulate := Color(1.3, 1.3, 1.3)

var original_modulates: Array[Color]

signal mouse_entered
signal mouse_exited
##Sends this antennas global position
signal selected(selected_antenna_position: Vector2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	for button in detection_areas:
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)
		button.pressed.connect(_on_pressed)
		button.disabled = true
	for node in highlighted_nodes:
		original_modulates.append(node.self_modulate)

func _on_mouse_entered():
	mouse_entered.emit()

func _on_mouse_exited():
	mouse_exited.emit()

func _on_pressed():
	selected.emit(global_position)

func highlight():
	self_modulate = mouse_hover_modulate
	for node in highlighted_nodes:
		node.modulate = mouse_hover_modulate

func unhighlight():
	self_modulate = Color(1,1,1,1)
	for i in range(highlighted_nodes.size()):
		highlighted_nodes[i].modulate = original_modulates[i]

func activate():
	visible = true
	for button in detection_areas:
		button.disabled = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_broadcasting(broadcasting: bool):
	if broadcasting:
		play_with_signals("active")
	else:
		play_with_signals("inactive")
	
	
	
