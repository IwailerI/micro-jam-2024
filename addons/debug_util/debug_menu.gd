class_name DebugMenu
## TODO: documentation

static var _NOOP_CALLABLE := func(_arg: Variant) -> void: pass

static var _instance: Node = null

## Adds the DebugMenu node to the scene tree. If the node is already present,
## does nothing.[br]
## [i]Note[/i]: every other method already calls wakes up the menu.
static func wake_up() -> void:
	if not OS.has_feature("debug"):
		return
	if _instance:
		return
	_instance = load("res://addons/debug_util/ignore_on_export/debug_menu/debug_menu_node.tscn").instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	assert(tree, "invalid main loop")
	tree.root.call_deferred("add_child", _instance)

	await _instance.ready

## Moves element with the given key to the provided index. Index 0 - element is
## at the top, bigger - lower. Value will be clamped to the child amount, so
## value of [code]1<<30[/code] can be used to mode the child to the bottom.
static func move_element(key: Variant, index: int) -> void:
	if not OS.has_feature("debug"):
		return
	await wake_up()
	_instance.move_element(key, index)

## Removes the object with the given key. If the key does not exist, does
## nothing.
static func delete(key: Variant) -> void:
	if not OS.has_feature("debug"):
		return
	await wake_up()
	_instance.delete(key)

## Adds a new [RichTextLabel] with bbcode turned on. It will be updated on each
## frame.[br]
## - [param setup] ([code]func(RichTextLabel)->void[/code]) will be called once,
## as soon as the node is ready.[br]
## - [param updater] ([code]func(RichTextLabel)->void[/code]) will be called
## once per frame, to possibly update element's state.
## Updater will be called on each process frame.[br]
## If the key already existed, it's [param updater] will be overridden, but
## [param setup] will not be called a second time.
static func label(
	key: Variant,
	updater: Callable=_NOOP_CALLABLE,
	setup: Callable=_NOOP_CALLABLE,
) -> void:
	if not OS.has_feature("debug"):
		return
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	custom(key, label, updater, setup)

## Adds a new [Button]. It will be updated on each frame.[br]
## - [param setup] ([code]func(RichTextLabel)->void[/code]) will be called once,
## as soon as the node is ready.[br]
## - [param updater] ([code]func(RichTextLabel)->void[/code]) will be called
## once per frame, to possibly update element's state.
## Updater will be called on each process frame.[br]
## If the key already existed, it's [param updater] will be overridden, but
## [param setup] will not be called a second time.
static func button(
	key: Variant,
	updater: Callable=_NOOP_CALLABLE,
	setup: Callable=_NOOP_CALLABLE
) -> void:
	if not OS.has_feature("debug"):
		return
	custom(key, Button.new(), updater, setup)

static func custom(
	key: Variant,
	instance: Control,
	updater: Callable=_NOOP_CALLABLE,
	setup: Callable=_NOOP_CALLABLE,
) -> void:
	if not OS.has_feature("debug"):
		return
	await wake_up()
	_instance.custom(key, instance, updater, setup)
