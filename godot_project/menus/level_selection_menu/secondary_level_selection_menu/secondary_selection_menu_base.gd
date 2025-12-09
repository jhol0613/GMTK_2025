extends Node2D

@export var world_number := 0

@onready var _level_list_container = $MarginContainer/VBoxContainer/LevelListContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var levels = GameManager.level_catalog.world_definitions[world_number].level_list
	for i in range(levels.size()):
		var level_button = LevelSelectButton.new(world_number, i)
		_level_list_container.add_child(level_button)
