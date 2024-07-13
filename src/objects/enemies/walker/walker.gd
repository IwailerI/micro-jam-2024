extends Area2D
class_name Walker

@export var speed: float = 150.0
@export var wanted_distance: float = 100.0
@export var perfect_distance: bool = false
@export var attack_range: float = 120.0
@export var push_apart_force: float = 100.0
@export var enemy_distance: float = 80.0
@export var knockback_accel: float = 700.0
@export var damage: int = 30

var player: Player = null
var stun_left: float = 0.0
var knockback: Vector2 = Vector2.ZERO

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurtable: Hurtable = $Hurtable
@onready var hurt_box: Area2D = get_node_or_null("HurtBox")

func _ready() -> void:
	hurtable.died.connect(func() -> void:
		animation_player.play("death"))

func _physics_process(delta: float) -> void:
	position += knockback * delta
	knockback = knockback.move_toward(Vector2.ZERO, knockback_accel * delta)
	push_apart(delta)
	stun_left -= delta # TODO: stun animation?
	if hurtable.is_dead or stun_left > 0.0:
		return

	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			return
		animation_player.play("idle")

	if player.hurtable.is_dead:
		animation_player.play("idle")
		return
	walk(delta)

func walk(delta: float) -> void:
	var player_dir := global_position.direction_to(player.global_position)
	var target_pos := player.global_position - player_dir * wanted_distance
	var player_dist_2 := global_position.distance_squared_to(player.global_position)

	if player_dist_2 > wanted_distance * wanted_distance * 1.1:
		global_position += global_position.direction_to(target_pos) * speed * delta
	elif perfect_distance and player_dist_2 < wanted_distance * wanted_distance * 0.9:
		global_position += global_position.direction_to(target_pos) * speed * delta
	
	rotation = player_dir.angle()

	if player_dist_2 < attack_range * attack_range:
		animation_player.play("punch")
	else:
		animation_player.play("run")

func push_apart(delta: float) -> void:
	for node: Node2D in get_tree().get_nodes_in_group("Enemy"):
		if node == self:
			continue
		var dist2 := node.global_position.distance_squared_to(global_position)
		if dist2 > enemy_distance * enemy_distance:
			continue
		var dir := node.global_position.direction_to(global_position)
		global_position += (remap(dist2, 0, enemy_distance * enemy_distance, 1, 0)
				* dir * push_apart_force * delta)

func attack() -> void:
	var nodes: Array[Node2D] = hurt_box.get_overlapping_bodies()
	nodes.append_array(hurt_box.get_overlapping_areas())

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")
		h.hurt(damage)

func stun(duration: float) -> void:
	stun_left = maxf(stun_left, duration)