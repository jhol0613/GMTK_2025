extends Node2D

class_name RotateButtons

@export var button_group: ButtonGroup

@export var _left_button : TextureButton
@export var _right_button : TextureButton

@onready var _position := 0

var _left_stop = -99999999
var _right_stop = 99999999

signal direction_pressed(direction: Enums.Direction)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_left_pressed():
	direction_pressed.emit(Enums.Direction.LEFT)
	_position -= 1
	_right_button.disabled = false
	if _position == _left_stop:
		_left_button.disabled = true

func _on_right_pressed():
	direction_pressed.emit(Enums.Direction.RIGHT)
	_position += 1
	_left_button.disabled = false
	if _position == _right_stop:
		_right_button.disabled = true

#how far something can be rotated left or right from its initial position
func set_limits(left_stop: int, right_stop: int):
	_left_stop = left_stop
	_right_stop = right_stop
	_left_button.disabled = false
	_right_button.disabled = false
	if _position <= _left_stop:
		_position = _left_stop
		_left_button.disabled = true
	if _position >= _right_stop:
		_position = _right_stop
		_right_button.disabled = true

##Resets limits position
func reset():
	_position = 0
	set_limits(_left_stop, _right_stop)
