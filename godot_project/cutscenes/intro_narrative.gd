extends Control

@onready var _conductor = $conductor
@onready var passenger_and_player = $passenger_and_player
@onready var _bench = $bench
@onready var _benchback = $bench/bench_back

func _ready() -> void:
	AudioManager.set_music_mode(Enums.MusicMode.THINKING)


func _on_timer_timeout() -> void:
	_bench.visible = false
	_benchback.visible = false


func _on_passenger_and_player_animation_finished() -> void:
	GameManager.load_scene(Enums.Scenes.LEVEL_MANAGER)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipLevel"):
		GameManager.load_scene(Enums.Scenes.LEVEL_MANAGER)


func _on_skip_hint_timer_timeout() -> void:
	if $SkipHint.visible:
		$SkipHint.visible = false
		$SkipHintTimer.stop()
	else:
		$SkipHint.visible = true


func _on_start_timer_timeout() -> void:
	_conductor.play("default")
	passenger_and_player.play("default")
	pass # Replace with function body.
