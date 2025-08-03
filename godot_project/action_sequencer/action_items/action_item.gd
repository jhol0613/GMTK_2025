extends Control

class_name ActionItem

@onready var texture_rect = $TextureRect
@onready var border = $Border
@onready var light = $PointLight2D
@onready var flash_timer = $Timer

@export var preview_scene : PackedScene
@export var icon_dictionary: Dictionary[Enums.PlayerAction, CompressedTexture2D]

@export var flash_time := .3
@export var max_flashes := 6

var flash_count = 0
var flashing = false

var action: Enums.PlayerAction
var quantity: int
var selected := false

signal action_item_clicked(clicked_action_item: ActionItem)
signal stopped_flashing(ActionItem)

func _ready() -> void:
	border.modulate.a = 0
	
	
func set_action(new_action: Enums.PlayerAction):
	action = new_action
	texture_rect.texture = icon_dictionary.get(action)
	#texture_rect.size = icon_size
	

func decrease_quantity():
	quantity -= 1
	# TODO: update quantity UI here

func flash():
	flashing = true
	flash_count = 0
	flash_timer.start(flash_time)
	
func stop_flashing():
	flash_timer.stop()
	set_light_on(false)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag_preview = preview_scene.instantiate()
	set_drag_preview(drag_preview)
	drag_preview.set_icon(texture_rect.texture)
	return {
		"type": "item",
		"action": action,
		"quantity": quantity,
		"reference": self,
		"texture": texture_rect.texture
	}


func _on_texture_rect_mouse_entered() -> void:
	if not selected:
		texture_rect.position.y += -1

func _on_texture_rect_mouse_exited() -> void:
	if not selected:
		texture_rect.position.y += 1


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if flashing:
			stopped_flashing.emit(self)
			stop_flashing()
			
		# Use modulate alpha instead of visibility so changing visibility doesn't affect layout
		if not selected:
			border.modulate.a = 1
			light.visible = true
			texture_rect.position.y += 1
			selected = true
			action_item_clicked.emit(self)

		
		
func deselect():
	border.modulate.a = 0
	light.visible = false
	selected = false
	
func set_light_on(on: bool):
	if on:
		border.modulate.a = 1
		light.visible = true
	else:
		border.modulate.a = 0
		light.visible = false

func toggle_light():
	if light.visible:
		set_light_on(false)
	else:
		set_light_on(true)

func _on_flash_timer_timeout() -> void:
	if flash_count == max_flashes:
		stop_flashing()
		return
	flash_count += 1
	toggle_light()
	pass # Replace with function body.
