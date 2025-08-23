extends AnimatedSprite2D


##A sprite 2D with the ability to attach signals to animation frames
class_name AnimatedSprite2DSignals

##Data containing a dictionary of signals that should be emitted at certain frames in the animation player
@export var signals: Array[Sprite2DSignalData]

signal animation_signal(signal_id: String)
	
func play_with_signals(name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false):
	play(name, custom_speed, from_end)
	if !sprite_frames.has_animation(name):
		return
		
	var signals = _get_signals(name)
	for sig in signals:
		var timer = get_tree().create_timer(_get_time_at_frame(name, sig.frame))
		timer.timeout.connect(_on_timeout.bind(sig.signal_id))

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
	for i in range(sprite_frames.get_frame_count(animation_name)):
		frame_time += sprite_frames.get_frame_duration(animation_name, frame_number) * single_frame_duration
		
	return frame_time
		
	
