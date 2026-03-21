extends Node

## A collection of functions for handling save files

var solutions_path = "res://levels/solutions/world%d/level%d/"
var solutions_template = "solution%d.tres"

func save_solution(solution: Array[Enums.PlayerAction], level_index: Dictionary, index: int) -> bool:
	print("[SaveManager] Trying to save solution #%d for world(%d) level(%d)" %\
		[index, level_index["world"], level_index["level"]])
	var solution_path = (solutions_path + solutions_template) %\
		[level_index["world"], level_index["level"], index]
	# ensures that the solutions/world directory exists
	DirAccess.make_dir_recursive_absolute(solutions_path % [level_index["world"], level_index["level"]])

	var saved_solution = SavedSolution.new(solution)
	var result = ResourceSaver.save(saved_solution, solution_path)
	return result == OK

func load_solution(level_index: Dictionary, index: int) -> Array[Enums.PlayerAction]:
	print("[SaveManager] Trying to load solution #%d for world(%d) level(%d)" %\
		[index, level_index["world"], level_index["level"]])
	var solution_path = (solutions_path + solutions_template) %\
		[level_index["world"], level_index["level"], index]
	if not FileAccess.file_exists(solution_path):
		print("[SaveManager] file doesn't exist")
		return []

	var solutions: Array[Enums.PlayerAction] = []
	var result = ResourceLoader.load(solution_path)
	if result is SavedSolution:
		solutions = result.sequence
	return solutions
