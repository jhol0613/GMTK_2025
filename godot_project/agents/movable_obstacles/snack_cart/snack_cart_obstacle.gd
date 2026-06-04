extends MovableObstacle

@export_group("Antenna Data")
@export var button_size_horizontal := Vector2(39, 60)
@export var button_position_horizontal := Vector2(-17, -59)
@export var antenna_position_horizontal := Vector2(-12, -49)
@export var button_size_vertical := Vector2(20,60)
@export var button_position_vertical := Vector2(-12, -59)
@export var antenna_position_vertical := Vector2(-5, -51)

@onready var antenna := $AntennaComponent
@onready var antenna_button := $Button

func _ready():
	super._ready()
	sprite.animation_signal.connect(_on_animation_played)

func _on_animation_played(signal_id):
	if signal_id == "vertical_move":
		antenna_button.size = button_size_vertical
		antenna_button.position = button_position_vertical
		antenna.position = antenna_position_vertical
	elif signal_id == "horizontal_move":
		antenna_button.size = button_size_horizontal
		antenna_button.position = button_position_horizontal
		antenna.position = antenna_position_horizontal
