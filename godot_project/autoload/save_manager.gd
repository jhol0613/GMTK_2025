extends Node

## A collection of functions for handling save files

var solutions_path = "res://levels/solutions/"
var solutions_template = "%s_solution%d.tres"

var save_data_path = "user://save_data.tres"

# Don't forget to save_game() after modifying this!
var save_data: SaveData
var enable_save := true

#region Solutions

func save_solution(solution: Array[Enums.PlayerAction], uid: int, index: int) -> bool:
	var text_uid = ResourceUID.id_to_text(uid)
	print("[SaveManager] Trying to save solution (new) #%d for %s" %\
		[index, text_uid])
	var solution_path = (solutions_path + solutions_template) %\
			[text_uid.trim_prefix("uid://"), index]
	# ensures that the solutions/world directory exists
	DirAccess.make_dir_recursive_absolute(solutions_path)

	var saved_solution = SavedSolution.new(solution)
	var result = ResourceSaver.save(saved_solution, solution_path)
	return result == OK

func load_solution(uid: int, index: int) -> Array[Enums.PlayerAction]:
	var text_uid = ResourceUID.id_to_text(uid)
	print("[SaveManager] Trying to load solution (new) #%d for %s" %\
		[index, text_uid])
	var solution_path = (solutions_path + solutions_template) %\
			[text_uid.trim_prefix("uid://"), index]
	if not FileAccess.file_exists(solution_path):
		print("[SaveManager] file doesn't exist")
		return []

	var solutions: Array[Enums.PlayerAction] = []
	var result = ResourceLoader.load(solution_path)
	if result is SavedSolution:
		solutions = result.sequence
	return solutions

#endregion

#region Save data
func _ready() -> void:
	if not FileAccess.file_exists(save_data_path):
		save_data = SaveData.new()
		save_data.furthest_level_reached["world"] = GameManager.start_world
		save_data.furthest_level_reached["level"] = GameManager.start_level
		save_game()
	else:
		load_game()


##Save current game state to the file
func save_game() -> void:
	if not enable_save:
		return
	var result = ResourceSaver.save(save_data, save_data_path)
	if result != OK:
		push_error("[SaveManager] Couldn't save game!")


##Load game state from the file
func load_game() -> void:
	var result = ResourceLoader.load(save_data_path)
	if result == null or result is not SaveData:
		push_error("[SaveManager] Loaded save data is not correct!")
		return
	save_data = result


##Adds the collectible into save file, saves automatically.
func add_collectible(collectible: String) -> void:
	if save_data.collectibles_acquired.has(collectible):
		return
	save_data.collectibles_acquired.append(collectible)
	save_game()


##Removes the collectible from the save file, saves automatically
func remove_collectible(collectible: String) -> void:
	if not save_data.collectibles_acquired.has(collectible):
		return
	save_data.collectibles_acquired.erase(collectible)
	save_game()


func update_furthest_level(index: Dictionary) -> void:
	if index["world"] > save_data.furthest_level_reached["world"] or\
		index["world"] == save_data.furthest_level_reached["world"] and\
		index["level"] > save_data.furthest_level_reached["level"]:
		save_data.furthest_level_reached = index
		save_game()


func add_completed_level(uid: int) -> void:
	save_data.completed_levels[uid] = true
	save_game()

#endregion
