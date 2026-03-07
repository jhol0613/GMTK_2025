@tool
extends Agent


class_name Teleporter

##In-level grid position of the destination tile
@export var destination := Vector2i.ZERO:
	set(new_destination):
		destination = new_destination.clamp(Vector2i.ZERO, grid_size - Vector2i.ONE)
		_update_target_position()
##The downbeat is beat 0.0
@export var push_beat := 2.0
@export var move_mode := Enums.MoveMode.ON_BEAT


@onready var sound := $FmodEventEmitter2D
@onready var collision := $Area2D
@onready var target_sprite := $TargetSprite

# Editor-only variables

## We don't have all initialized variables in _ready(), so wait until _process()
var _editor_has_target := false

func _ready() -> void:
	super._ready()
	add_to_group("teleporters")
	if not Engine.is_editor_hint():
		AudioManager.music_bar.connect(_on_music_bar)

#region Editor-only reticle


func _process(_delta: float) -> void:
	if not _editor_has_target:
		_editor_has_target = true
		_update_target_position()


func _update_target_position() -> void:
	if not target_sprite:
		return
	target_sprite.position = Vector2((destination - grid_origin) * tile_size)


#endregion

func _teleport(entity: Movable) -> void:
	# TODO: add animation
	# TODO: add sound
	#print("Queueing teleport for %s" % entity)
	entity.queue_teleportation(destination)


func _on_music_bar():
	if move_mode == Enums.MoveMode.ON_BEAT:
		get_tree().create_timer(push_beat * AudioManager.beat_time_seconds).timeout.connect(_on_push_beat_timeout)
	else:
		_on_push_beat_timeout()


func _on_push_beat_timeout():
	for area in collision.get_overlapping_areas():
		if area.owner is Movable:
			_teleport(area.owner)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.owner is not Movable or move_mode != Enums.MoveMode.INSTANT:
		return

	_teleport(area.owner)
