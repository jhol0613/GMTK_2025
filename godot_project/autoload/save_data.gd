extends Resource

class_name SaveData

# store UIDs!
@export var completed_levels: Dictionary[int, bool] = {}
@export var furthest_level_reached: Dictionary = {"world": 0, "level": 0}
@export var collectibles_acquired : Array[String] = []
@export var version := 1 # update on each save data revision

func _init(current_level: Dictionary = {"world": 0, "level": 0}, levels: Dictionary[int, bool] = {}, collectibles: Array[String] = [], ver: int = 1) -> void:
	completed_levels = levels
	collectibles_acquired = collectibles
	version = ver
	furthest_level_reached = current_level
