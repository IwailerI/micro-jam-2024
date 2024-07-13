extends Area2D

@export var speed: float = 200.0
@export var fuse: float = 3.0
@export var base_knockback: float = 500.0
@export var base_damage: int = 300
@export var stun_time: float = 2.0

@onready var radius: float = $DetonationArea/CollisionShape2D["shape"]["radius"] / scale.x
@onready var sprite: Sprite2D = $Sprite2D
@onready var tail_particles: CPUParticles2D = $CPUParticles2D
@onready var detonation_particles: CPUParticles2D = $DetonationParticles
@onready var detonation_area: Area2D = $DetonationArea

func _ready() -> void:
	body_entered.connect(func(_arg: Object) -> void: detonate())
	area_entered.connect(func(_arg: Object) -> void: detonate())
	get_tree().create_timer(fuse, false, true).timeout.connect(detonate)
	($Hurtable as Hurtable).died.connect(detonate)
	tail_particles.emitting = true

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
		h.hurt(base_damage)
		h.knockback(global_position.direction_to(node.global_position) * base_knockback)

		if node.is_in_group("Stunable"):
			node.call("stun", stun_time)

	set_physics_process(false)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
