extends MovableObstacle

class_name MovingInteractable

@export var interactable: Interactable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	interactable.global_position = global_position
	pass
