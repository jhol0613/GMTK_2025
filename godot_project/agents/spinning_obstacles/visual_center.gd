extends Node2D

##Since y sort is determined by the actual origin of the node, it can be helpful to have another point
##represent the "visual origin". Agents that move other agents (e.g. spinning chair) can use this point
##as a reference to update relative position
class_name VisualCenter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
