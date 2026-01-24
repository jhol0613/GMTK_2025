extends Line2D

@export var max_beam_length := 1000.0
@export var direction := Enums.Direction.UP

@onready var ray := $RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_target(max_beam_length_vector):
	ray.target_position = Enums.direction_to_vector(direction) * max_beam_length

#Three cases: 
# 1. Gets to max beam length (end case, draw laser end)
# 2. Hits laser blocker (new segment drawn under/over as required)
# 3. Hits end of laser blocker (new segment drawn back on main layer)
func _fire() -> void:
	ray.force_raycast_update()
	if not ray.is_colliding():
		points[1] = ray.target_position
	
