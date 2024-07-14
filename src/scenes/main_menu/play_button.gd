extends TextureButton

const MAIN_SCENE := preload ("res://src/scenes/tutorial/tutorial.tscn")

func _pressed() -> void:
	ScreenTransition.change_scene_to_packed(MAIN_SCENE)
