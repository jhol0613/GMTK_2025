extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_test_text(new_text: String):
	$Label.text = new_text
