extends CenterContainer

const MAIN_SCENE := preload ("res://src/scenes/field/field.tscn")

@onready var button: Button = %Button

func _ready() -> void:
	button.pressed.connect(func() -> void:
		ScreenTransition.change_scene_to_packed(MAIN_SCENE))
