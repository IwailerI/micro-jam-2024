class_name DebugDrawer
extends Node2D
## A class to quickly draw anything anywhere anytime.
##
## [DebugDrawer] can be used to draw anything anywhere anytime. It has 2 methods
## to control drawing: [method draw] and [method stop].
## Caveats:[br]
## - Will push a warning upon creation.[br]
## - Will not draw anything in release builds.[br]
## - Will not work if [MainLoop] is not [SceneTree].

# Lazy singleton instance.
static var _instance: DebugDrawer = null:
	get:
		if not _instance:
			_instance = DebugDrawer._create_instance()
		return _instance

# Dictionary which maps keys to their respective updater Callable.
var _updaters := {}

## Adds or updates the given key with the [param updater]. It will be called
## once per frame during the [method _draw] callback. It must receive one
## parameter of type [DebugDrawer]. Arrays and dictionaries are automatically
## hashed and the hash is used as the key.
static func draw(key: Variant, updater: Callable) -> void:
	if key is Array or key is Dictionary:
		key = hash(key)
	DebugDrawer._instance._updaters[key] = updater

## Stop drawing previously defined key. Does nothing if key is not defined.
## Arrays and dictionaries are automatically hashed and the hash is used as the
## key.
static func stop(key: Variant) -> void:
	if key is Array or key is Dictionary:
		key = hash(key)
	DebugDrawer._instance._updaters[key].erase(key)

static func _create_instance() -> DebugDrawer:
	var tree := Engine.get_main_loop() as SceneTree
	assert(tree, "invalid main loop type")

	var instance := Node2D.new()
	instance.set_script(DebugDrawer)
	tree.root.call_deferred("add_child", instance)

	return instance

func _ready() -> void:
	if OS.has_feature("release") or not OS.has_feature("debug"):
		set_process(false)
		push_error("DebugDrawer created, but it will do nothing, because this"
				+ " is a release build")
	else:
		push_warning("DebugDrawer created")

func _process(_delta: float) -> void:
	if OS.has_feature("release") or not OS.has_feature("debug"):
		set_process(false)
		return

	queue_redraw()

func _draw() -> void:
	if OS.has_feature("release") or not OS.has_feature("debug"):
		set_process(false)
		return

	for updater: Callable in _updaters.values():
		updater.call(self)

func draw_arrow(
	from: Vector2,
	to: Vector2,
	color: Color,
	head_size: float=3.0,
	head_angle: float=45.0,
	width:=- 1.0,
) -> void:
	var off1 := (from - to).rotated(deg_to_rad(head_angle)).normalized() * head_size
	var off2 := (from - to).rotated(deg_to_rad( - head_angle)).normalized() * head_size
	draw_multiline([
		from, to,
		to, to + off1,
		to, to + off2
	], color, width)

func draw_vector(
	origin: Vector2,
	vector: Vector2,
	color: Color,
	head_size: float=3.0,
	head_angle: float=45.0,
	width:=- 1.0,
) -> void:
	draw_arrow(origin, origin + vector, color, head_size, head_angle, width)

func draw_position(
	pos: Vector2,
	color: Color,
	extents:=10.0,
	width:=- 1.0
) -> void:
	draw_multiline([
		pos + Vector2.RIGHT * extents, pos - Vector2.RIGHT * extents,
		pos + Vector2.DOWN * extents, pos - Vector2.DOWN * extents,
	], color, width)
