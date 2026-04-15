@tool
extends Agent


class_name Teleporter

@export var teleporter_color : Enums.TeleporterColor = Enums.TeleporterColor.GREEN: set = _set_color
##In-level grid position of the destination tile. Active destination will always start as the 
@export var destination := Vector2i.ZERO:
	set(new_destination):
		destination = _validate_destination(new_destination)
		_update_target_position()
##The downbeat is beat 0.0
@export var move_mode := Enums.MoveMode.ON_BEAT
@export var top : TeleporterTop
@export_group("Animation")
@export var respawn_delay := .2
##Because modulate values need to be grreater than 1 to get to white, multiply the selected teleporter color
##(as defined in the script by teleporter_color_definitions) by this value
@export var modulate_multiplier := 3.0
##Amount of time to show modulated version of teleported entity before they disappear
@export var despawn_modulate_time := .6
##Nodes that should be modulated by the teleporter color (this shouldn't have to be changed)
@export var modulate_nodes : Array[Node2D]
##Glowing light nodes
@export var glow_nodes: Array[Light2D]
@export var teleporter_color_definitions : Dictionary[Enums.TeleporterColor, Color] = {
	Enums.TeleporterColor.PINK: Color("ec29cd"),
	Enums.TeleporterColor.GREEN: Color("285224"),
	Enums.TeleporterColor.BLUE: Color("2677eb")
}

@onready var sound := $FmodEventEmitter2D
@onready var collision := $Area2D
@onready var base_sprite_lights := $Node2D/TeleporterBaseFront/Lights
@onready var target_sprite : AnimatedSprite2DSignals = $Target/YSortOffset/TargetSprite
@onready var target_sprite_lights : AnimatedSprite2DSignals = $Target/YSortOffset/TargetSprite/Lights
@onready var despawn_particles : Array[GPUParticles2D] = [
	$TeleporterBaseBack/DespawnParticles/DespawnParticles,
	$TeleporterBaseBack/DespawnParticles/DespawnParticles2,
	$TeleporterBaseBack/DespawnParticles/DespawnParticles3,
	$TeleporterBaseBack/DespawnParticles/DespawnParticles4
]
@onready var respawn_particles : Array[GPUParticles2D] = [
	$Target/YSortOffset/TargetSprite/Lights/RespawnParticles,
	$Target/YSortOffset/TargetSprite/Lights/RespawnParticles2,
	$Target/YSortOffset/TargetSprite/Lights/RespawnParticles3,
	$Target/YSortOffset/TargetSprite/Lights/RespawnParticles4
]
@onready var initial_target_sprite_offset = target_sprite.position

# set in runtime, found dynamically using its name
var _level_scene: RhythmRailLevel

# Editor-only variables

## We don't have all initialized variables in _ready(), so wait until _process()
var _editor_has_target := false

##Don't allow teleported entities to immediately teleport again
var teleport_cooldown_list : Array[Movable]

##Array of targets for the various potential destinations
var destination_targets : Array[TeleporterTarget]

var teleport_animation_tween: Tween

##Flag to indicate aborted teleport if teleported entity has been freed
var _teleport_aborted

##Notify level manager that something teleported so it can tell other teleporters not to teleport it
signal something_teleported(Movable)

func _ready() -> void:
	super._ready()
	add_to_group("teleporters")
	for child in get_children():
		if child is TeleporterTarget:
			destination_targets.append(child)
	if not Engine.is_editor_hint():
		AudioManager.music_bar.connect(_on_music_bar)
	if not top:
		return
	_set_color(teleporter_color)
	if AudioManager.beat_time_seconds * default_action_beat < top.lights_sprite.default_animation_offset:
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

func _set_color(new_color):
	teleporter_color = new_color
	#target_sprite_glow.color = teleporter_color_definitions[teleporter_color]
	for node: Node2D in modulate_nodes:
		var color = teleporter_color_definitions[teleporter_color]
		color.v *= modulate_multiplier
		node.modulate = color
	for light: Light2D in glow_nodes:
		light.color = teleporter_color_definitions[teleporter_color]
	if top:
		var color = teleporter_color_definitions[teleporter_color]
		for light in top.lights:
			light.color = color
		color.v *= modulate_multiplier
		top.lights_sprite.modulate = color

#endregion

#Need to check teleport aborted flag after every await call
func _teleport(entity: Movable) -> void:
	entity.tree_exited.connect(_abort_teleport)
	var original_modulate = entity.modulate
	something_teleported.emit(entity)
	entity.interrupt_queued_action(true)
	
	if entity is PlayerCharacter: #special case for player character since we have art for it
		entity.queue_teleportation(destination)
		entity.visible = false
		base_sprite_lights.play_with_signals("player_teleport")
		await base_sprite_lights.animation_signal # only signal should be when it's time for particles to play
		if _teleport_aborted:
			_teleport_aborted = false
			return
	else:
		# set to appropriate color and brighten slightly since entity is probably not coming from grayscale image
		entity.modulate = teleporter_color_definitions[teleporter_color] * Color(1.5, 1.5, 1.5, 0.8) 
		teleport_animation_tween = get_tree().create_tween()
		teleport_animation_tween.tween_method(
			_stairstep_tween.bind(entity), 
			Vector2(1,1), 
			Vector2(0,0), 
			# object teleport animation should take the same time as player teleport animation
			base_sprite_lights.get_animation_duration("player_teleport")
		)
		await teleport_animation_tween.finished
		if _teleport_aborted:
			_teleport_aborted = false
			return
		entity.queue_teleportation(destination)
	_play_despawn_particles()
	await get_tree().create_timer(respawn_delay).timeout
	if _teleport_aborted:
		_teleport_aborted = false
		return
	_play_respawn_particles()
	if entity is not PlayerCharacter:
		teleport_animation_tween = get_tree().create_tween()
		teleport_animation_tween.tween_method(
			_stairstep_tween.bind(entity), 
			Vector2(0,0), 
			Vector2(1,1), 
			# object teleport animation should take the same time as player teleport animation
			base_sprite_lights.get_animation_duration("player_teleport")
		)
	await get_tree().create_timer(respawn_delay).timeout
	if _teleport_aborted:
		_teleport_aborted = false
		return
	base_sprite_lights.play_with_signals("default")
	if entity is PlayerCharacter:
		target_sprite_lights.play_with_signals("respawn_player")
	else:
		target_sprite_lights.play_with_signals("respawn_object")
	#signal is when object should reappear in respawn animation
	await target_sprite_lights.animation_signal
	if _teleport_aborted:
		_teleport_aborted = false
		return
	entity.visible = true
	if entity is not PlayerCharacter:
		#await get_tree().create_timer(respawn_modulate_time).timeout
		entity.modulate = original_modulate

func _stairstep_tween(value: Vector2, entity):
	entity.scale = floor(value * 5.0) / 5.0 #lazy coding. Currently hardcoded to frame rate of 5 for this tween

##Stop trying to teleport if teleport entity has been freed
func _abort_teleport():
	if teleport_animation_tween:
		teleport_animation_tween.stop()
	_teleport_aborted = true

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
			await get_tree().create_timer(default_action_beat * AudioManager.beat_time_seconds + \
				top.lights_sprite.default_animation_offset).timeout
			top.power_up()
			await top.powered_up #top sprite should only emit one signal, so no need to check signal id
			_on_push_beat_timeout()
		else:
			get_tree().create_timer(default_action_beat * AudioManager.beat_time_seconds).timeout.connect(_on_push_beat_timeout)
	else:
		_on_push_beat_timeout()


func _on_push_beat_timeout():
	for area in collision.get_overlapping_areas():
		if area.owner is Movable and not teleport_cooldown_list.has(area.owner):
			_teleport(area.owner)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if teleport_cooldown_list.has(area.owner):
		return
	if area.owner is not Movable or move_mode != Enums.MoveMode.INSTANT:
		return
	_teleport(area.owner)
