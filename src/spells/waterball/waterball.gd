extends Area2D

@export var speed: float = 400.0
@export var fuse: float = 1.5
@export var base_knockback: float = 1000.0
@export var knockback_curve: Curve
@export var base_damage: float = 500.0
@export var damage_curve: Curve

var radius: float

@onready var sprite: Sprite2D = $Sprite2D
@onready var tail_particles: CPUParticles2D = $CPUParticles2D
@onready var detonation_particles: CPUParticles2D = $DetonationParticles
@onready var detonation_area: Area2D = $DetonationArea

func _ready() -> void:
	body_entered.connect(func(_arg: Object) -> void: detonate())
	area_entered.connect(func(_arg: Object) -> void: detonate())
	get_tree().create_timer(fuse, false, true).timeout.connect(detonate)
	tail_particles.emitting = true

	# forgive me father for i have sinned
	radius = ((detonation_area.get_child(0) as CollisionShape2D).shape as CircleShape2D).radius

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func detonate() -> void:
	sprite.hide()
	detonation_particles.emitting = true
	tail_particles.emitting = false

	var nodes: Array[Node2D] = detonation_area.get_overlapping_bodies()
	nodes.append_array(detonation_area.get_overlapping_areas())

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")

		var distance := clampf(
				node.global_position.distance_to(global_position) / radius,
				0.0, 1.0)

		h.hurt(ceili(base_damage * damage_curve.sample(distance)))
		h.knockback(global_position.direction_to(node.global_position)
				* base_knockback * knockback_curve.sample(distance))

	set_physics_process(false)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
