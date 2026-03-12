@tool
extends Agent


class_name Teleporter

##In-level grid position of the destination tile
@export var destination := Vector2i.ZERO:
	set(new_destination):
		destination = _validate_destination(new_destination)
		_update_target_position()
##The downbeat is beat 0.0
@export var move_mode := Enums.MoveMode.ON_BEAT
@export var top : TeleporterTop
@export var initial_target_sprite_offset := Vector2(0, 0)


@onready var sound := $FmodEventEmitter2D
@onready var collision := $Area2D
@onready var base_sprite := $Node2D/TeleporterBaseFront
@onready var target_sprite : AnimatedSprite2DSignals = $Target/YSortOffset/TargetSprite

# set in runtime, found dynamically using its name
var _level_scene: RhythmRailLevel

##time in seconds that warmup animation should start before actual teleportation happens
var _animation_offset: float

# Editor-only variables

## We don't have all initialized variables in _ready(), so wait until _process()
var _editor_has_target := false

func _ready() -> void:
	super._ready()
	add_to_group("teleporters")
	if not Engine.is_editor_hint():
		AudioManager.music_bar.connect(_on_music_bar)
	if not top:
		return
	if AudioManager.beat_time_seconds * default_action_beat < top.sprite.default_animation_offset:
		push_warning("Teleporter powerup animation can't be triggered because it would bleed into the
		previous bar. Either reduce teleporter top animation offset or move teleporter action beat later")

#region Editor-only reticle


func _process(_delta: float) -> void:
	if not _editor_has_target:
		_editor_has_target = true
		# only here we have the guarantee that LevelBase exists
		_level_scene = find_parent("LevelBase")
		_update_target_position()


func _validate_destination(new_destination: Vector2i) -> Vector2i:
	new_destination = new_destination.clamp(Vector2i.ZERO, grid_size - Vector2i.ONE)
	if not _level_scene:
		return new_destination
	if _level_scene.has_static_obstacle(new_destination):
		new_destination = destination
	return new_destination

func _update_target_position() -> void:
	if not target_sprite:
		return
	target_sprite.position = Vector2((destination - grid_origin) * tile_size) + initial_target_sprite_offset


#endregion

func _teleport(entity: Movable) -> void:
	if entity is PlayerCharacter: #special case for player character since we have art for it
		entity.visible = false
		base_sprite.play_with_signals("player_teleport")
		await base_sprite.animation_finished
		base_sprite.play_with_signals("default")
	# TODO: add animation
	# TODO: add sound
	#print("Queueing teleport for %s" % entity)
	entity.queue_teleportation(destination)
	_play_respawn_animation()
	entity.visible = true

##Play this animation at teleporter origin when something gets teleported
func _play_despawn_animation():
	pass
 
##Play this animation at teleporter target on getting teleported to destination
func _play_respawn_animation():
	target_sprite.play_with_signals("respawn")

func _on_music_bar():
	if move_mode == Enums.MoveMode.ON_BEAT:
		if top:
			await get_tree().create_timer(default_action_beat * AudioManager.beat_time_seconds + top.sprite.default_animation_offset).timeout
			top.sprite.play_with_signals("power_up")
			await top.sprite.animation_signal #top sprite should only emit one signal, so no need to check signal id
			_on_push_beat_timeout()
		else:
			get_tree().create_timer(default_action_beat * AudioManager.beat_time_seconds).timeout.connect(_on_push_beat_timeout)
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
