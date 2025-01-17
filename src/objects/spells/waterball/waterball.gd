extends Area2D

@export var speed: float = 400.0
@export var fuse: float = 1.5
@export var base_knockback: float = 1000.0
@export var knockback_curve: Curve
@export var base_damage: float = 500.0
@export var damage_curve: Curve

var soap := false

@onready var radius: float = $DetonationArea/CollisionShape2D["shape"]["radius"] / scale.x
@onready var sprite: Sprite2D = $Sprite2D
@onready var tail_particles: CPUParticles2D = $CPUParticles2D
@onready var detonation_particles: CPUParticles2D = $DetonationParticles
@onready var detonation_area: Area2D = $DetonationArea
@onready var sfx: AudioStreamPlayer = %ExplodeSFX

func _ready() -> void:
	body_entered.connect(func(node: Node2D) -> void: hit(node))
	area_entered.connect(func(node: Node2D) -> void: hit(node))
	get_tree().create_timer(fuse, false, true).timeout.connect(detonate)
	($Hurtable as Hurtable).died.connect(detonate)
	tail_particles.emitting = true

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func hit(node: Node2D) -> void:
	if not node.is_in_group(Hurtable.GROUP):
		return
	var h: Hurtable = node.get_node("Hurtable")
	h.hurt(base_damage)
	detonate()

func detonate() -> void:
	sprite.hide()
	detonation_particles.emitting = true
	tail_particles.emitting = false

	var nodes: Array[Node2D] = detonation_area.get_overlapping_bodies()
	nodes.append_array(detonation_area.get_overlapping_areas())

	sfx.play()

	var sm := Player.SOAP_MULTIPLIER if soap else 1.0

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")

		var distance := clampf(
				node.global_position.distance_to(global_position) / radius,
				0.0, 1.0)

		h.hurt(ceili(base_damage * damage_curve.sample(distance) * sm))
		h.knockback(global_position.direction_to(node.global_position)
				* base_knockback * knockback_curve.sample(distance) * sm)

	set_physics_process(false)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
