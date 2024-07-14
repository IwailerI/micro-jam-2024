extends CanvasLayer

const MASTER_BUS: int = 0
const MUSIC_BUS: int = 1
const SFX_BUS: int = 3

@onready var master_slider: HSlider = %MasterSlider
@onready var master_label: Label = %MasterLabel
@onready var music_slider: HSlider = %MusicSlider
@onready var music_label: Label = %MusicLabel
@onready var effects_slider: HSlider = %EffectsSlider
@onready var effects_label: Label = %EffectsLabel
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	hide()
	master_slider.value_changed.connect(func(v: float) -> void:
		master_label.text="%d%%" % remap(v, -80, 0, 0, 100)
		AudioServer.set_bus_volume_db(MASTER_BUS, v))
	music_slider.value_changed.connect(func(v: float) -> void:
		music_label.text="%d%%" % remap(v, -80, 0, 0, 100)
		AudioServer.set_bus_volume_db(MUSIC_BUS, v))
	effects_slider.value_changed.connect(func(v: float) -> void:
		effects_label.text="%d%%" % remap(v, -80, 0, 0, 100)
		AudioServer.set_bus_volume_db(SFX_BUS, v))
	close_button.pressed.connect(func() -> void:
		if get_tree().paused and not visible:
			return
		get_tree().paused = not get_tree().paused
		visible = not visible
		get_viewport().set_input_as_handled())
	tree_exiting.connect(save_settings)

	load_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_settings"):
		if get_tree().paused and not visible:
			return
		get_tree().paused = not get_tree().paused
		visible = not visible
		get_viewport().set_input_as_handled()

func save_settings() -> void:
	var data := {
		"audio/master": AudioServer.get_bus_volume_db(MASTER_BUS),
		"audio/music": AudioServer.get_bus_volume_db(MUSIC_BUS),
		"audio/effects": AudioServer.get_bus_volume_db(SFX_BUS),
	}
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_settings() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	if not f:
		return
	var data := JSON.parse_string(f.get_as_text()) as Dictionary
	master_slider.value = data.get("audio/master", 0.0) as float
	music_slider.value = data.get("audio/music", 0.0) as float
	effects_slider.value = data.get("audio/effects", 0.0) as float
