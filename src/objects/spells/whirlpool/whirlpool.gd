extends Area2D

## Damage per second
@export var dps: float = 20
@export var lifetime: float = 5.0
## Rotation speed in turns per second.
@export var rotation_speed: float = 0.2
@export var fade_in: float = 1.0
@export var pull_velocity: float = 800.0
@export var side_velocity: float = 800.0

var enemies := {}
var strength: float = 1.0
var radius: float
var soap := false

@onready var fg: Node2D = $FG
@onready var bg: Node2D = $BG

func _ready() -> void:
	get_tree().create_timer(lifetime - 0.5, false, true).timeout.connect(destroy)
	radius = (($CollisionShape2D as CollisionShape2D).shape as CircleShape2D).radius

func _physics_process(delta: float) -> void:
	fg.rotation += 2 * PI * rotation_speed * delta
	bg.rotation -= 2 * PI * rotation_speed * delta

	var sm := Player.SOAP_MULTIPLIER if soap else 1.0

	var nodes: Array[Node2D] = []
	nodes.append_array(get_overlapping_areas())
	nodes.append_array(get_overlapping_bodies())
	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var dir := node.global_position.direction_to(global_position)
		var side_power := remap(node.global_position.distance_to(global_position), 0, radius, 0, 1.0)
		var velocity := (dir * pull_velocity * strength
				+ dir.rotated(PI * 0.5) * side_velocity * strength * side_power)
		var h: Hurtable = node.get_node("Hurtable")
		h.hurt(ceili(dps * delta * sm))
		h.knockback(velocity * delta)

func destroy() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	t.tween_property(self, "strength", 0.0, 0.5)
	t.chain().tween_callback(queue_free)
