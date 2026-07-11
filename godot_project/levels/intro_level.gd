extends RhythmRailLevel

@onready var animation_player = $AnimationPlayer
@onready var intro_music = $FmodEventEmitter2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("conductor_walk")
