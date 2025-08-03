extends Agent


class_name Conductor

signal player_caught


func _on_player_entered(area: Area2D) -> void:
	player_caught.emit()
