extends Window

var nodes := {}
var updaters := {}

@onready var container: VBoxContainer = %Container

func _ready() -> void:
	if not OS.has_feature("debug"):
		queue_free()
		return

	if not InputMap.has_action("debug_menu_toggle"):
		push_warning('"debug_menu_toggle" action is not defined; default F4 bind will be used')
		InputMap.add_action("debug_menu_toggle")
		var ev := InputEventKey.new()
		ev.keycode = KEY_F4
		InputMap.action_add_event("debug_menu_toggle", ev)

	close_requested.connect(func() -> void: hide())

	container.add_child(
		preload ("res://addons/debug_util/ignore_on_export/debug_menu/time_scale/time_scale.tscn")
		.instantiate())

	(
		func() -> void:
			while true:
				await get_tree().create_timer(15.0, true, false, true).timeout
				_save_data()
	).call_deferred()

	var file := FileAccess.open("user://debug_menu_data.json", FileAccess.READ)
	if not file:
		return
	# assume everything is good and user has not tampered with file :)
	var text := file.get_as_text()
	var json := JSON.parse_string(text)
	position = Vector2(json.position[0], json.position[1])
	size = Vector2(json.size[0], json.size[1])
	visible = json.visible

func _exit_tree() -> void:
	_save_data()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_menu_toggle"):
		self.visible = not self.visible

	if not self.visible:
		return

	for key in nodes.keys():
		updaters[key].call(nodes[key])

func move_element(key: Variant, index: int) -> void:
	if key is Array or key is Dictionary:
		key = hash(key)
	var node: Node = nodes.get(key, null)
	if not node:
		return
	index = clampi(index, -container.get_child_count(), container.get_child_count())
	container.move_child(node, index)

func delete(key: Variant) -> void:
	if key is Array or key is Dictionary:
		key = hash(key)
	nodes.erase(key)
	updaters.erase(key)

func custom(
	key: Variant,
	instance: Control,
	updater: Callable,
	setup: Callable,
) -> void:
	if key is Array or key is Dictionary:
		key = hash(key)

	if nodes.has(key):
		nodes[key].queue_free()

	nodes[key] = instance
	updaters[key] = updater
	instance.ready.connect(setup.bind(instance), CONNECT_ONE_SHOT)
	instance.ready.connect(updater.bind(instance), CONNECT_ONE_SHOT)
	container.add_child(instance)

func _save_data() -> void:
	var data := {
		"position": [position.x, position.y],
		"size": [size.x, size.y],
		"visible": visible,
	}
	var json := JSON.stringify(data)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	FileAccess.open("user://debug_menu_data.json", FileAccess.WRITE).store_string(json)
