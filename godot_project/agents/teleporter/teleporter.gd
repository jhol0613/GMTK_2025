@tool
extends Agent


class_name Teleporter

##In-level grid position of the destination tile
@export var destination := Vector2i.ZERO:
	set(new_destination):
		destination = new_destination
		if Engine.is_editor_hint():
			_debug_update_target_position()
##The downbeat is beat 0.0
@export var push_beat := 2.0
@export var move_mode := Enums.MoveMode.ON_BEAT


@onready var sound := $FmodEventEmitter2D
@onready var collision := $Area2D

# Editor-only variables

## Reticle that follows the destination coordinates, visible only in editor
var _editor_only_target: Sprite2D
## We can't get LevelBase in _ready, so we need to track if we have set the target's position or not
var _editor_has_target := false
## Hard-coded target texture
var _target_scene: CompressedTexture2D = preload("res://agents/teleporter/teleporter_target.png")


func _ready() -> void:
	super._ready()
	add_to_group("teleporters")
	if not Engine.is_editor_hint():
		AudioManager.music_bar.connect(_on_music_bar)

#region Editor-only reticle


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not _editor_has_target:
		_editor_has_target = true
		_debug_update_target_position()



func _debug_update_target_position() -> void:
	var level_base: RhythmRailLevel = find_parent("LevelBase")
	if not level_base or not level_base._floor_layer:
		return
	if not _editor_only_target:
		_editor_only_target = Sprite2D.new()
		_editor_only_target.texture = _target_scene
		add_child(_editor_only_target)
	_editor_only_target.global_position = level_base.map_to_local(destination)


#endregion

func _teleport(entity: Movable) -> void:
	# TODO: add animation
	# TODO: add sound
	entity.set_grid_position(destination)


func _on_music_bar():
	if move_mode == Enums.MoveMode.ON_BEAT:
		_on_push_beat_timeout()
		#get_tree().create_timer(push_beat * AudioManager.beat_time_seconds).timeout.connect(_on_push_beat_timeout)


func _on_push_beat_timeout():
	for area in collision.get_overlapping_areas():
		if area.owner is Movable:
			_teleport(area.owner)
