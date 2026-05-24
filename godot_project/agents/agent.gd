extends Node2D

class_name Agent

@export_subgroup("Starting Position")
##agent's initial position in the grid
@export var grid_origin := Vector2i.ZERO

@export_subgroup("Action Beats")
##On which beat should an action "execute". This is the anchor point for the whole action and is tied
##to bpm. Offsets to sounds and animations can be applied individually, and those offsets are based off of
##the beats defined here. Keep in mind beats here are 0 indexed, so the downbeat is beat 0.0
@export var action_beats: Dictionary[Enums.PlayerAction, float]
##The action beat to use when nothing is defined for a particular action (downbeat = 0.0)
@export var default_action_beat := 0.0
##If not empty, agent will only perform an action on the beats in the sequence marked "true". For example,
##for a laser with [false, true], laser would fire every second beat
@export var activation_sequence : Array[bool]

@export_subgroup("Sounds")

##Sound emitter for each action
@export var action_sound_emitters: Dictionary[Enums.PlayerAction, FmodEventEmitter2DOffset]
##Play this emitter if no emitter is defined for a particular action
@export var default_sound_emitter: FmodEventEmitter2D

@export_subgroup("Animation")
@export var sprite: AnimatedSprite2DSignals
##Animation names from the animated sprite for actions
@export var action_animations: Dictionary[Enums.PlayerAction, String]
##If a follow-on animation is defined for a given action, that animation will play after an action animation is finished (e.g. idle in the proper direction)
@export var follow_on_animations: Dictionary[Enums.PlayerAction, String]
##Default animation will play if animation is not defined for a specific action
@export var default_animation: String

##Timer for delaying action_executed signal to the beat defined in action_beats (or default_action_beat)
@onready var _action_timer = Timer.new()
##Timer for delaying sound to desired beat
@onready var _sound_timer = Timer.new()
##Timer for delaying animation to desired beat
@onready var _animation_timer = Timer.new()

var currently_playing_emitter: FmodEventEmitter2DOffset

##agent's position inside of the grid
var grid_position := Vector2i(0, 0)
##grid's tile size for calculating the local position
var tile_size: Vector2i
##grid's bound size
var grid_size := Vector2i.MAX
##grid origin in local coordinate space. This should be the coordinate space where position is calculated,
##i.e. local with respect to the level itself. It should include the difference between a cell's top left
##corner vice its center as well as any offset from parents (i.e. nodes between the agent and and the level
##in the node hierarchy
var local_origin := Vector2.ZERO: set = _set_local_origin
var lock_local_origin = false

# Emitted on the actual beat of an action
signal action_executed(action: Enums.PlayerAction)

# Pass on signals from agent's animation sprite
signal animation_signal(id: String)

func _ready() -> void:
	add_to_group("agents")

	#Set up timers for sound and animation offsets
	_action_timer.one_shot = true
	_sound_timer.one_shot = true
	_animation_timer.one_shot = true
	add_child(_sound_timer)
	add_child(_animation_timer)
	add_child(_action_timer)
	_action_timer.timeout.connect(_on_action_beat)
	_sound_timer.timeout.connect(_on_sound_start)
	_animation_timer.timeout.connect(_on_animation_start)

	assert(sprite != null, "Sprite not defined for agent " + name)

	#Connect to animation signals to feed up to level manager
	if sprite != null:
		sprite.connect("animation_signal", _on_animation_signal)

func reset() -> void:
	grid_position = grid_origin
	position = _grid_to_local(grid_position)
	if default_animation != "":
		sprite.play_with_signals(default_animation)
	_reset_timer(_action_timer)
	_reset_timer(_sound_timer)
	_reset_timer(_animation_timer)
	if currently_playing_emitter:
		currently_playing_emitter.stop()

func _reset_timer(timer: Timer):
	if timer:
		timer.stop()

func execute_action(action : Enums.PlayerAction, beat: int, skip_animation := false) -> void:
	if not check_activation_for_beat(beat):
		return
	# Determine amount of time before action, sound, and animation are executed (in seconds)
	var action_delay = _get_action_delay_in_seconds(action)#action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds

	# Determine delay for FMOD event emitter
	var sound_delay = _get_sound_delay_in_seconds(action)

	var animation_delay = _get_animation_delay_in_seconds(action)# action_delay + sprite.get_animation_offset_seconds(action_animations.get(action, default_animation))

	_execute_callable_on_timer(_action_timer, action_delay, _on_action_beat.bind(action))
	_execute_callable_on_timer(_sound_timer, sound_delay, _on_sound_start.bind(action))
	if skip_animation:
		return
	_execute_callable_on_timer(_animation_timer, animation_delay, _on_animation_start.bind(action))

##Return true if action should be executed this beat based on activation sequence, false otherwise. Negative beat will always return true
func check_activation_for_beat(beat: int):
	if beat >= 0 and (not activation_sequence.is_empty()):
		if not activation_sequence[beat % activation_sequence.size()]:
			return false
	return true



## Helper to help manage timing signals for action emitter, animation, sound, etc.
func _execute_callable_on_timer(timer: Timer, delay: float, callable: Callable):
	if delay <= 0.0:
		if delay < 0.0:
			push_error("Timing offset for " + name + " sound, animation, or movement is prior to downbeat")
		callable.call()
		return
	if timer.is_connected("timeout", callable):
		timer.timeout.disconnect(callable)
	timer.stop()
	timer.timeout.connect(callable)
	timer.start(delay)

func interrupt_queued_action(cancel_sound := true):
	if _animation_timer.is_connected("timeout", _on_animation_start):
		_animation_timer.disconnect("timeout", _on_animation_start)
	if _action_timer.is_connected("timeout", _on_action_beat):
		_action_timer.disconnect("timeout", _on_action_beat)
	if _sound_timer.is_connected("timeout", _on_sound_start) and cancel_sound:
		_sound_timer.disconnect("timeout", _on_sound_start)
		if currently_playing_emitter:
			currently_playing_emitter.stop()
	_animation_timer.stop()

	if cancel_sound:
		interrupt_queued_sound()

func interrupt_queued_sound():
	if _sound_timer.is_connected("timeout", _on_sound_start):
		_sound_timer.disconnect("timeout", _on_sound_start)
	if currently_playing_emitter:
		currently_playing_emitter.stop()
	_sound_timer.stop()

func _on_action_beat(action: Enums.PlayerAction):
	action_executed.emit(action)

func _on_sound_start(action: Enums.PlayerAction):
	#Play sound
	currently_playing_emitter = action_sound_emitters.get(action, null)
	#switch to default sound if no specific sound defined for a given action, unless that action is specifically defined as no sound
	if not currently_playing_emitter and default_sound_emitter and not action_sound_emitters.has(action): 
		currently_playing_emitter = default_sound_emitter
	if currently_playing_emitter and action != Enums.PlayerAction.NONE:
		currently_playing_emitter.play()

func _on_animation_start(action: Enums.PlayerAction):
	var animation_name = action_animations.get(action, default_animation)
	var follow_on = follow_on_animations.get(action, "")
	play_animation_with_follow_on(animation_name, follow_on)

#Cancel current follow-on anim by setting follow_on_animation to "cancel_follow_on"
func play_animation_with_follow_on(animation_name: String, follow_on_animation := ""):
	#assert(sprite.sprite_frames.get_animation_names().has(animation_name), "Attempting to call play animation that does not exist")
	sprite.play_with_signals(animation_name)
	if follow_on_animation == "cancel_follow_on":
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)
	elif follow_on_animation != "":
		if not sprite.animation_finished.has_connections():
			sprite.animation_finished.connect(_on_animation_finished.bind(follow_on_animation))

func _on_animation_finished(follow_on_animation: String):
	sprite.play_with_signals(follow_on_animation)
	sprite.animation_finished.disconnect(_on_animation_finished)

##Returns time delay for an action to execute on the defined beat
func _get_action_delay_in_seconds(action: Enums.PlayerAction) -> float:
	return action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds

##Returns proper sound offset in seconds taking into account both target beat and the sound's individual offset parameter
func _get_sound_delay_in_seconds(action: Enums.PlayerAction) -> float:
	var emitter: FmodEventEmitter2DOffset = action_sound_emitters.get(action, default_sound_emitter)
	# if no action beat defined, just use the downbeat
	if emitter:
		return action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds + emitter.offset_seconds
	else:
		return action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds

##Returns proper animation offset in seconds taking into account both target beat and animation's individual offset parameter
func _get_animation_delay_in_seconds(action: Enums.PlayerAction) -> float:
	var animation_name = action_animations.get(action, default_animation)
	return action_beats.get(action, default_action_beat) * AudioManager.beat_time_seconds + sprite.get_animation_offset_seconds(animation_name)

func _grid_to_local(grid_coordinates: Vector2i) -> Vector2:
	return local_origin + Vector2(grid_coordinates * tile_size)

func _on_animation_signal(signal_id):
	animation_signal.emit(signal_id)

#only allow local origin to be set once, as required, by the level
func _set_local_origin(new_local_origin: Vector2):
	if not lock_local_origin:
		local_origin = new_local_origin
		lock_local_origin = true

func _unlock_set_local_origin():
	lock_local_origin = false
