extends AnimatedSprite2D


##A sprite 2D with the ability to attach signals to animation frames, and hold data for an offset from the beat
class_name AnimatedSprite2DSignals

##Data containing a dictionary of signals that should be emitted at certain frames in the animation player
@export var signals: Array[Sprite2DSignalData]

##When the animation should be offset from the defining beat (e.g. a jump might happen on beat 2, but the warmup
##animation might need to start a few seconds prior). If synch_framerates_to_bpm is true, these offsets should be
##beats. If it's false, these offsets should be seconds. Note that this is just a data field. The owning class must
##implement the actual offset.
@export var animation_offsets: Dictionary[String, float]

@export var default_animation_offset := 0.0

##If true, frame rate stays synched to bpm
@export var synch_framerates_to_bpm := true
##Even if synch framerates to bmp is true, these animations won't synch to bpm
@export var bpm_synch_exceptions: Array[String]

##Beats per second
var old_bps

signal animation_signal(signal_id: String)

func _ready():
	old_bps = AudioManager.bpm * .01666666666 #1/60
	if synch_framerates_to_bpm:
		AudioManager.bpm_changed.connect(_on_bpm_changed)
	
func play_with_signals(animation_name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false):
	play(animation_name, custom_speed, from_end)
	if !sprite_frames.has_animation(animation_name):
		return

	var signal_frames = _get_signals(animation_name)
	for frame_number in signal_frames:
		var timer = get_tree().create_timer(_get_time_at_frame(animation_name, frame_number))
		timer.timeout.connect(_on_timeout.bind(signal_frames.get(frame_number)))

##Returns default animation offset (typically 0.0) if animation doesn't exist
func get_animation_offset_seconds(animation_name: String) -> float:
	if not sprite_frames.has_animation(animation_name):
		return default_animation_offset
	if synch_framerates_to_bpm: # calculate seconds from beats if synching frames to bpm
		return animation_offsets.get(animation_name, default_animation_offset) * AudioManager.beat_time_seconds
	else: #just use seconds if not synching frames to bpm
		return animation_offsets.get(animation_name, default_animation_offset)
	

func _on_timeout(signal_id: String):
	animation_signal.emit(signal_id)
	
func _on_bpm_changed(new_bpm: float):
	for animation_name in sprite_frames.get_animation_names():
		if bpm_synch_exceptions.has(animation_name):
			continue
		# Use the frame rate set in the animation player to determine what to multiply the new frame rate by. 
		# e.g. If bpm is 170 (5.67 frame rate) and the frame rate defined in the animation player is 12.0, frame
		# rate for beat_synched animation will be 11.3333
		var animation_speed_multiplier = roundf(sprite_frames.get_animation_speed(animation_name) / AudioManager.get_fps_from_bpm(old_bps * 60.0))
		sprite_frames.set_animation_speed(animation_name, AudioManager.get_fps_from_bpm() * animation_speed_multiplier)
		
	old_bps = new_bpm * .01666666666 #1/60

## Returns dictionary of ints corresponding to frames and the signal id attached to that frame
func _get_signals(animation_name: String) -> Dictionary[int, String]:
	var signal_frames:  Dictionary[int, String]
	for sig in signals:
		if sig.animation == animation_name:
			signal_frames[sig.frame] = sig.signal_id
	return signal_frames
	
func _get_time_at_frame(animation_name: String, frame_number: int):
	var frame_time := 0.0
	var single_frame_duration = 1.0 / sprite_frames.get_animation_speed(animation_name)
	for i in range(frame_number):
		frame_time += sprite_frames.get_frame_duration(animation_name, i) * single_frame_duration
		
	return frame_time
		
	
