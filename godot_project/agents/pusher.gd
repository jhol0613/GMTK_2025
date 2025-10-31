extends Area2D

class_name Pusher

@export_subgroup("behavior")
@export var push_action := Enums.PlayerAction.UP
##Whether to perform push on specific beat, or immediately on overlap detection
@export var push_mode := Enums.PushMode.ON_BEAT
##The downbeat is beat 0.0
@export var push_beat := 2.0
##If true, push action will cancel the sound that was queued with the action. If not, push action
##sound will just play on top of the queud action sound
@export var should_cancel_sound := true

##Use this instead of setting collision layers directly
@export_subgroup("collision")
##Use this instead of setting collision layers directly
@export_flags_2d_physics var pusher_collision_layer: int = 16 : set = _set_collision_layer
##Use this instead of setting collision layers directly
@export_flags_2d_physics var pusher_collision_mask: int = 133 : set = _set_collision_mask

#Returns self and overlapped movable
signal overlapped_movable(pusher: Pusher, movable: Movable)

# Set a new default collision layer and mask when dropped in the editor
func _init() -> void:
	collision_layer = pusher_collision_layer
	collision_mask = pusher_collision_mask #player and enemies

func _set_collision_layer(new_layer):
	pusher_collision_layer = new_layer
	collision_layer = pusher_collision_layer

func _set_collision_mask(new_layer):
	pusher_collision_mask = new_layer
	collision_mask = pusher_collision_mask

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("pushers") # this is how level knows to find pushers that are added to scene
	AudioManager.music_bar.connect(_on_music_bar)

func _on_area_entered(overlapped_area: Area2D):	
	if push_mode == Enums.PushMode.INSTANT:
		overlapped_movable.emit(self, overlapped_area.owner)
			
func _on_music_bar():
	if push_mode == Enums.PushMode.ON_BEAT:
		get_tree().create_timer(push_beat * AudioManager.beat_time_seconds).timeout.connect(_on_push_beat_timeout)
	# Trigger overlaps again if movable is still overlapping
	#for area in get_overlapping_areas():
		#_on_area_entered(area)
		
func _on_push_beat_timeout():
	# No check that it's a movable because mask should already be set appropriately
	for overlapped_area in get_overlapping_areas():
		overlapped_movable.emit(self, overlapped_area.owner)
