extends Area2D

@export var speed: float = 700.0
@export var damage: int = 50
@export var knockback: float = 900.0
@export var lifetime: float = 2.0
@export var fade_in: float = 0.5

var soap := false
var sticky := {}

func _ready() -> void:
	get_tree().create_timer(lifetime, false, true).timeout.connect(destroy)
	modulate.a = 0
	create_tween().tween_property(self, "modulate", Color.WHITE, fade_in)
	body_entered.connect(_node_collided)
	area_entered.connect(_node_collided)

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

	var sm := Player.SOAP_MULTIPLIER if soap else 1.0

	for node: Variant in sticky.keys():
		if not node:
			sticky.erase(node)
			continue
		node.global_position = global_position + sticky[node]
		var hurtable: Hurtable = node.get_node("Hurtable")
		hurtable.hurt(ceili(damage / lifetime * delta * sm))

func _node_collided(node: Node2D) -> void:
	if not node.is_in_group(Hurtable.GROUP) or sticky.has(node):
		return
	sticky[node] = node.global_position - global_position

func destroy() -> void:
	var sm := Player.SOAP_MULTIPLIER if soap else 1.0
	for node: Node2D in sticky:
		var hurtable: Hurtable = node.get_node("Hurtable")
		hurtable.knockback(Vector2.RIGHT.rotated(rotation) * knockback * sm)
	sticky.clear()
	var t := create_tween()
	t.tween_property(self, "modulate", Color.TRANSPARENT, fade_in)
	t.chain().tween_callback(queue_free)
