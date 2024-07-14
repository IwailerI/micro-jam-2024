extends TextureButton

const MAIN_SCENE := preload ("res://src/scenes/field/field.tscn")

func _pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_SCENE)
