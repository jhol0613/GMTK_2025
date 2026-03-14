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
@export_category("Animation")
@export var respawn_delay := .2
##The color to modulate entities when they teleport since not every entity has a bespoke teleport animation
@export var teleported_entity_modulate := Color("#64bc5a")
##Amount of time to show modulated version of teleported entity before they disappear
@export var despawn_modulate_time := .6
##Amount of time to show modulated version of teleported entity when they respawn before going back to normal
@export var respawn_modulate_time := .6


@onready var sound := $FmodEventEmitter2D
@onready var collision := $Area2D
@onready var base_sprite := $Node2D/TeleporterBaseFront
@onready var target_sprite : AnimatedSprite2DSignals = $Target/YSortOffset/TargetSprite
@onready var despawn_particles : Array[GPUParticles2D] = [
	$TeleporterBaseBack/DespawnParticles,
	$TeleporterBaseBack/DespawnParticles2,
	$TeleporterBaseBack/DespawnParticles3,
	$TeleporterBaseBack/DespawnParticles4
]
@onready var respawn_particles : Array[GPUParticles2D] = [
	$Target/YSortOffset/TargetSprite/RespawnParticles,
	$Target/YSortOffset/TargetSprite/RespawnParticles2,
	$Target/YSortOffset/TargetSprite/RespawnParticles3,
	$Target/YSortOffset/TargetSprite/RespawnParticles4
]
@onready var initial_target_sprite_offset = target_sprite.position

# set in runtime, found dynamically using its name
var _level_scene: RhythmRailLevel

# Editor-only variables

## We don't have all initialized variables in _ready(), so wait until _process()
var _editor_has_target := false

##Don't allow teleported entities to immediately teleport again
var teleport_cooldown_list : Array[Movable]

##Notify level manager that something teleported so it can tell other teleporters not to teleport it
signal something_teleported(Movable)

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
	if top:
		top.modulate = modulate


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
	var original_modulate = entity.modulate
	something_teleported.emit(entity)
	entity.interrupt_queued_action(true)
	entity.queue_teleportation(destination)
	if entity is PlayerCharacter: #special case for player character since we have art for it
		entity.visible = false
		base_sprite.play_with_signals("player_teleport")
		await base_sprite.animation_signal # only signal should be when it's time for particles to play
	else:
		entity.modulate = teleported_entity_modulate
	_play_despawn_particles()
	if entity is not PlayerCharacter:
		await get_tree().create_timer(despawn_modulate_time).timeout
	await get_tree().create_timer(respawn_delay).timeout
	_play_respawn_particles()
	await get_tree().create_timer(respawn_delay).timeout
	base_sprite.play_with_signals("default")
	if entity is PlayerCharacter:
		target_sprite.play_with_signals("respawn_player")
	else:
		target_sprite.play_with_signals("respawn_object")
	#signal is when object should reappear in respawn animation
	await target_sprite.animation_signal
	entity.visible = true
	if entity is not PlayerCharacter:
		await get_tree().create_timer(respawn_modulate_time).timeout
		entity.modulate = original_modulate

##Play this animation at teleporter origin when something gets teleported
func _play_despawn_particles():
	for particle_system in despawn_particles:
		particle_system.emitting = true

##Play this animation at teleporter target on getting teleported to destination
func _play_respawn_particles():
	for particle_system in respawn_particles:
		particle_system.emitting = true

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
	if teleport_cooldown_list.has(area.owner):
		return
	if area.owner is not Movable or move_mode != Enums.MoveMode.INSTANT:
		return
	_teleport(area.owner)
