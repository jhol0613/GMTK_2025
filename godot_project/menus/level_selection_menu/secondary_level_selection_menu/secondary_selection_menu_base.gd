extends Node2D

@export var world_number := 0

@onready var _levels_container = $MarginContainer/VBoxContainer2/ScrollContainer/LevelListContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var levels = GameManager.level_catalog.world_definitions[world_number].levels
	for i in range(levels.size()):
		var level_button = LevelSelectButton.new(world_number, i)
		_levels_container.add_child(level_button)
