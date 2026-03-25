extends Node2D


class_name DigipadCycle

@export var number_of_options := 2

@onready var left_button = $Left
@onready var right_button = $Right
@onready var option_label = $OptionLabel
@onready var index = 0

signal option_cycled(index: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	left_button.pressed.connect(_on_button_pressed.bind(-1))
	right_button.pressed.connect(_on_button_pressed.bind(1))
	option_label.text = String.chr(index + 65)

func _on_button_pressed(index_shift):
	index += index_shift
	index = posmod(index, number_of_options)
	option_label.text = str(index)
	option_label.text = String.chr(index + 65)
	option_cycled.emit(index)
