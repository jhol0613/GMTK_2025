extends RhythmRailLevel

@onready var animation_player = $AnimationPlayer
@onready var intro_music = $FmodEventEmitter2D
@onready var conductor_sprite = $conductor
@onready var passenger_sprite = $passenger
@onready var player_sprite = $player_character

@onready var beat = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await AudioManager.music_bar
	conductor_sprite.speed_scale = animation_player.speed_scale
	passenger_sprite.speed_scale = animation_player.speed_scale
	player_sprite.speed_scale = animation_player.speed_scale
	animation_player.play("conductor_walk")
	#AudioManager.play_music_event("World1_BGM", 170.0, true, true)
	#AudioManager.music_bar.connect(_on_beat)
#
#func _on_beat():
	#print(beat)
