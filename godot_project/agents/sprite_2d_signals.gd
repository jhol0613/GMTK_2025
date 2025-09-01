extends AnimatedSprite2D


##A sprite 2D with the ability to attach signals to animation frames
class_name AnimatedSprite2DSignals

##Data containing a dictionary of signals that should be emitted at certain frames in the animation player
@export var signals: Array[Sprite2DSignalData]

signal animation_signal(signal_id: String)
	
func play_with_signals(animation_name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false):
	play(animation_name, custom_speed, from_end)
	if !sprite_frames.has_animation(name):
		return

	var signal_frames = _get_signals(name)
	for frame_number in signal_frames:
		var timer = get_tree().create_timer(_get_time_at_frame(name, frame_number))
		timer.timeout.connect(_on_timeout.bind(signal_frames.get(frame_number)))

func _on_timeout(signal_id: String):
	animation_signal.emit(signal_id)

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
		print(frame_time)
		
	return frame_time
		
	
