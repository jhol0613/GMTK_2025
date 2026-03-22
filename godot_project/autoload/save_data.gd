extends Resource

class_name SaveData

@export var furthest_level_reached: Dictionary = {"world": 0, "level": 0}
@export var collectibles_acquired : Array[String] = []

func _init(current_level: Dictionary = {"world": 0, "level": 0}, collectibles: Array[String] = []) -> void:
	furthest_level_reached = current_level
	collectibles_acquired = collectibles
