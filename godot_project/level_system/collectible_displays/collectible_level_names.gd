extends Node2D

@export var text_size := 12

@onready var labels := $LevelLabels
@onready var example_label := $LevelLabels/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var level_names = GameManager.level_catalog.get_collectible_level_names()
	for name in level_names:
		var label = example_label.duplicate()
		label.text = name
		labels.add_child(label)
	example_label.visible = false
		
