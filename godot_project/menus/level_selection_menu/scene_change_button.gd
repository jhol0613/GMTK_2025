extends Button

class_name SceneChangeButton

@export var destination_scene : Enums.Scenes

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	GameManager.load_scene(destination_scene, Enums.TransitionStyle.NONE)
