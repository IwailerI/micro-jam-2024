extends Area2D

@export var base_damage: float = 300.0
@export var base_knockback: float = 1000.0
@export var damage_curve: Curve
@export var knockback_curve: Curve

var soap := false

@onready var lifetime: float = $Particles["lifetime"]
@onready var radius: float = $CollisionShape2D["shape"]["radius"] * scale.x
@onready var sfx: AudioStreamPlayer = %ExplodeSFX

func _ready() -> void:
	var p: Player = get_tree().get_first_node_in_group("Player")
	global_position = p.global_position

	$Particles["emitting"] = true
	$ParticlesSplash["emitting"] = true

	get_tree().create_timer(lifetime * 1.2, false).timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	# janky, but works
	set_physics_process(false)
	await get_tree().physics_frame

	sfx.play()

	var sm := Player.SOAP_MULTIPLIER if soap else 1.0

	var nodes: Array[Node2D] = []
	nodes.append_array(get_overlapping_areas())
	nodes.append_array(get_overlapping_bodies())
	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")
		var distance := clampf(global_position.distance_to(node.global_position) / radius, 0, 1)
		var direction := global_position.direction_to(node.global_position)

		h.hurt(ceili(base_damage * damage_curve.sample(distance) * sm))
		h.knockback(direction * base_knockback * damage_curve.sample(distance) * sm)
