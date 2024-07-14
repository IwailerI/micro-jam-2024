extends CenterContainer

@onready var menu := load("res://src/scenes/main_menu/main_menu.tscn")
@onready var main := load("res://src/scenes/field/field.tscn")

@onready var replay_button: Button = %ReplayButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	get_tree().paused = false

	replay_button.pressed.connect(get_tree().change_scene_to_packed.bind(main))
	menu_button.pressed.connect(get_tree().change_scene_to_packed.bind(menu))
