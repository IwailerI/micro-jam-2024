extends CanvasLayer

const DEFAULT_VOLUME: float = 40.0
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
		master_label.text="%d%%" % v
		AudioServer.set_bus_volume_db(MASTER_BUS, calculate_volume(v)))
	music_slider.value_changed.connect(func(v: float) -> void:
		music_label.text="%d%%" % v
		AudioServer.set_bus_volume_db(MUSIC_BUS, calculate_volume(v)))
	effects_slider.value_changed.connect(func(v: float) -> void:
		effects_label.text="%d%%" % v
		AudioServer.set_bus_volume_db(SFX_BUS, calculate_volume(v)))
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

func calculate_volume(v: float) -> float:
	return 20.0 * log(clampf(v+1, 1.0, 100.0) / 51.0) if v > 0.0 else -80.0

func save_settings() -> void:
	var data := {
		"audio/master": master_slider.value,
		"audio/music": music_slider.value,
		"audio/effects": effects_slider.value,
	}
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_settings() -> void:
	master_slider.value = DEFAULT_VOLUME
	music_slider.value = DEFAULT_VOLUME 
	effects_slider.value = DEFAULT_VOLUME
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	if not f:
		return
	var data := JSON.parse_string(f.get_as_text()) as Dictionary
	master_slider.value = data.get("audio/master", DEFAULT_VOLUME) as float
	music_slider.value = data.get("audio/music", DEFAULT_VOLUME) as float
	effects_slider.value = data.get("audio/effects", DEFAULT_VOLUME) as float
