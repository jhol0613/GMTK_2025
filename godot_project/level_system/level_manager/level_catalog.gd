extends Resource

class_name LevelCatalog

@export var world_definitions: Array[WorldDefinition]

var _current_world := -1
var _current_level := -1
var _previous_world := -1

## Returns level at a given index. Updates state to returned level index
func get_level(world: int, level: int) -> PackedScene:
	assert(world < world_definitions.size(), str("World ", world, " is not defined"))
	assert(level < world_definitions[world].level_list.size(), str("Level ", level, " in World ", world, " is not defined"))
	_previous_world = _current_world
	_current_world = world
	_current_level = level
	return world_definitions[world].level_list[level]

## Given a rhythm rail level, returns a dictionary with the world and level number. Updates state to level index
func get_index(level: RhythmRailLevel) -> Dictionary:
	var index_dict = {"world": -1, "level": -1}
	for world_index in range(world_definitions.size()):
		for level_index in range(world_definitions[world_index].level_list.size()):
			if level.scene_file_path == world_definitions[world_index].level_list[level_index].resource_path:
				index_dict.set("world", world_index)
				index_dict.set("level", level_index)
				_previous_world = _current_world
				_current_world = world_index
				_current_level = level_index
				return index_dict
	return index_dict

## Returns display name that is defined in each rhythm rail level
func get_display_name(world: int, level: int):
	
	if world >= world_definitions.size():
		return "requested world index out of bounds"
	if level >= world_definitions[world].level_list.size():
		return "requested level index out of bounds"
	
	var level_state = world_definitions[world].level_list[level].get_state()
	for i in range(level_state.get_node_property_count(0)): #0 is always root node
		if level_state.get_node_property_name(0, i) == "display_name":
				return level_state.get_node_property_value(0, i)

## Returns the next level based on internal state. Updates state to returned level index. Returns null if level doesn't exist
func get_next_level() -> PackedScene:
	# check if any more levels in this world
	_previous_world = _current_world
	if _current_level + 1 < world_definitions[_current_world].level_list.size():
		_current_level += 1
		return world_definitions[_current_world].level_list[_current_level]
	# get next world with a least 1 level, return first level in that world
	_current_world += 1
	_current_level = 0
	while _current_world < world_definitions.size():
		if world_definitions[_current_world].level_list.size() > 0:
			return world_definitions[_current_world].level_list[_current_level]
		_current_world += 1
	return null

## Returns the level select scene associated with a given world	
func get_level_select_scene(world_number: int) -> Enums.Scenes:
	return world_definitions[world_number].level_select_scene
	
## Gets music event associated with current world
func get_world_music_event_name():
	return world_definitions[_current_world].music_event_name

## Returns true iff most recent get level was a world different from the previous
func is_new_world() -> bool:
	return !_previous_world == _current_world
	
func get_world_scene() -> PackedScene:
	return world_definitions[_current_world].world_scene

## Returns transition scene for current (most recently loaded level's) world
func get_transition_scene() -> PackedScene:
	return world_definitions[_current_world].transition_scene
	
	
