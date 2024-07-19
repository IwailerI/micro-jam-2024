extends Area2D

@export var speed: float = 700.0
@export var damage_per_second: int = 30 # will be divided by frames_per_attack
@export var frames_per_attack: int = 10
@export var knockback: float = 900.0
@export var lifetime: float = 2.0
@export var fade_in: float = 0.5

var soap := false
var sticky := {}
var damaged_timers := {}

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
		if damaged_timers[node] > 0:
			damaged_timers[node] -= 1
			continue
		var hurtable: Hurtable = node.get_node("Hurtable")
		hurtable.hurt(damage_per_second / frames_per_attack * sm)
		damaged_timers[node] = frames_per_attack

func _node_collided(node: Node2D) -> void:
	if not node.is_in_group(Hurtable.GROUP) or sticky.has(node):
		return
	sticky[node] = node.global_position - global_position
	damaged_timers[node] = 0

func destroy() -> void:
	var sm := Player.SOAP_MULTIPLIER if soap else 1.0
	for node: Node2D in sticky:
		var hurtable: Hurtable = node.get_node("Hurtable")
		hurtable.knockback(Vector2.RIGHT.rotated(rotation) * knockback * sm)
	sticky.clear()
	var t := create_tween()
	t.tween_property(self, "modulate", Color.TRANSPARENT, fade_in)
	t.chain().tween_callback(queue_free)
