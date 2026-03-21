class_name SavedSolution extends Resource

@export var sequence: Array[Enums.PlayerAction]

func _init(solution: Array[Enums.PlayerAction] = []) -> void:
	sequence = solution
