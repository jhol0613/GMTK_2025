extends Area2D

class_name Pusher

@export var direction := Enums.PlayerAction.UP
@export var mask := 5 #default is player and enemies

signal overlapped_movable(movable: Movable)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = 16 #layer 5
	area_entered.connect(_on_area_entered)
	add_to_group("pushers")

func _on_area_entered(overlapped_area: Area2D):
	if overlapped_area.owner is Movable:
		print("movable entered pusher")
		overlapped_movable.emit(overlapped_area.owner)
