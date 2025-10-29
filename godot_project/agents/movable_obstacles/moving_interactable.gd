extends MovableObstacle

class_name MovingInteractable

@export var interactable: Interactable

#Position components as desired in the editor, offsets stored at runtime
#The offset between the obstacle and the interactable in grid space
@onready var _grid_position_offset
#The offset between the obstacle and interactable in position space
@onready var _position_offset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_grid_position_offset = grid_position - interactable.grid_position
	_position_offset = interactable.position #position relative to obstacle
	action_executed.connect(_on_action_executed)

func _on_action_executed(action: Enums.PlayerAction):
	interactable.grid_position = grid_position + _grid_position_offset

# Could theoretically be turned off when movable's not moving, but performance savings probably negligible for added complexity
func _process(delta: float) -> void:
	interactable.global_position = global_position + _position_offset
	pass
