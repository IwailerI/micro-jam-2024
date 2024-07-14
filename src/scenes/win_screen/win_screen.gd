extends CenterContainer

@onready var menu := load("res://src/scenes/main_menu/main_menu.tscn")
@onready var main := load("res://src/scenes/tutorial/tutorial.tscn")

@onready var replay_button: Button = %ReplayButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	replay_button.pressed.connect(ScreenTransition.change_scene_to_packed.bind(main))
	menu_button.pressed.connect(ScreenTransition.change_scene_to_packed.bind(menu))

func hydrate(water_amount: int) -> void:
	call_deferred("_hydrate", water_amount)

func _hydrate(water_amount: int) -> void:
	if not is_node_ready():
		await ready
	(%WaterLabel as RichTextLabel).text %= water_amount
