extends Node2D

class_name LevelBanner

@onready var lifetime_timer = $Timer
@onready var parallax = $Parallax2D
@onready var label = $Parallax2D/AnimatedSprite2DSignals/Label
@onready var sprite = $Parallax2D/AnimatedSprite2DSignals
@onready var lights = $Parallax2D/AnimatedSprite2DSignals/Lights

var label_text_init: String
var scroll_speed_init: float
var type_init: Enums.LevelBannerType

func _init(type = Enums.LevelBannerType.BILLBOARD, text = "Your ad goes here!", scroll_speed = 120.0):
	label_text_init = text
	scroll_speed_init = scroll_speed

func set_type(type: Enums.LevelBannerType):
	match type:
		Enums.LevelBannerType.BILLBOARD:
			sprite.play_with_signals("billboard")
			lights.visible = true

func _ready() -> void:
	label.text = label_text_init
	parallax.autoscroll.x = -scroll_speed_init
	set_type(type_init)

func _on_lifetime_timer_timeout() -> void:
	queue_free()
