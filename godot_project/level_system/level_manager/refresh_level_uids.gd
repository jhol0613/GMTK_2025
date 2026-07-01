@tool
extends EditorScript

@export var level_uids_path := "res://level_system/level_manager/uid_map.tres"
@export var level_catalog_path := "res://level_system/level_manager/level_catalog.tres"

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var level_uids: UIDMap = load(level_uids_path)
	var level_catalog: LevelCatalog = load(level_catalog_path)
	level_uids.level_uids.clear()
	var paths = level_catalog.get_level_resource_paths()
	for path in paths:
		##Only works in editor!
		level_uids.level_uids[path] = ResourceLoader.get_resource_uid(path)
	ResourceSaver.save(level_uids, level_uids_path)
