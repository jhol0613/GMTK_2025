extends TextureButton

##Same as texture button but has data field for direction
class_name DirectionButton

@export var direction: Enums.Direction

##Just like normal pressed but passes its direction
signal pressed_direction(dir: Enums.Direction)

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	pressed_direction.emit(direction)
