extends Area2D

class_name ActionSlot

var _hovered := false

func is_hovered() -> bool:
	return _hovered

func _mouse_enter() -> void:
	_hovered = true

func _mouse_exit() -> void:
	_hovered = false
