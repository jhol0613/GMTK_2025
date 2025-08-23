extends Camera2D

@export var default_strength := 12.0
##Higher numbers = faster fade
@export var default_fade := 6.0

@onready var _shake_strength := default_strength
@onready var _shake_fade := default_fade

var rng = RandomNumberGenerator.new()
var _current_shake_strength := 0.0
var _shaking = true

func _ready() -> void:
	pass

func apply_shake(strength = default_strength, fade = default_fade):
	_current_shake_strength = strength
	_shake_fade = fade

func _process(_delta: float) -> void:
	if _current_shake_strength > 0:
		_current_shake_strength = lerpf(_current_shake_strength, 0, _shake_fade * _delta)
		offset = randomOffset()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("DebugAction"):
		apply_shake()


func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-_current_shake_strength, _current_shake_strength), 
		rng.randf_range(-_current_shake_strength, _current_shake_strength))
