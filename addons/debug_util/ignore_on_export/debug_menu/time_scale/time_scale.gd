extends PanelContainer

@onready var label: RichTextLabel = %RichTextLabel
@onready var spin_box: SpinBox = %SpinBox
@onready var button: Button = %Button
@onready var slider: HSlider = %HSlider

func _ready() -> void:
	slider.value_changed.connect(func(v: float) -> void: Engine.time_scale=v)
	spin_box.value_changed.connect(func(v: float) -> void: Engine.time_scale=v)
	button.pressed.connect(func() -> void: Engine.time_scale=1.0)

func _process(_delta: float) -> void:
	slider.set_value_no_signal(Engine.time_scale)
	spin_box.set_value_no_signal(Engine.time_scale)
	button.disabled = Engine.time_scale == 1.0
	label.text = "Timescale"
