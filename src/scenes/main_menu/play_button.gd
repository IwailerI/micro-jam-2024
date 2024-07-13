extends TextureButton

func _pressed():
	get_tree().change_scene_to_file("res://src/scenes/field/field.tscn")
