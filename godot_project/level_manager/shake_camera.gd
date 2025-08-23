extends Camera2D

@export var shake_strength := 8.0
##Higher numbers = faster fade
@export var shake_fade := 8.0

var rng = RandomNumberGenerator.new()
var _current_shake_strength := 0.0
var _shaking = true


func _ready() -> void:
	pass

func apply_shake():
	_current_shake_strength = shake_strength

func _process(_delta: float) -> void:
	if _current_shake_strength > 0:
		_current_shake_strength = lerpf(_current_shake_strength, 0, shake_fade * _delta)
		offset = randomOffset()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("DebugAction"):
		apply_shake()


func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-_current_shake_strength, _current_shake_strength), 
		rng.randf_range(-_current_shake_strength, _current_shake_strength))
