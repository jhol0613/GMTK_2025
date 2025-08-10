extends Camera2D

@export var randomStrangth := 30.0
@export var shakeFade := 5.0

var rng = RandomNumberGenerator.new()
var shake_strength := 0.0

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
