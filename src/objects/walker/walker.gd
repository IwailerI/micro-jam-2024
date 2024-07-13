extends Area2D

@export var speed: float = 150.0
@export var wanted_distance: float = 118.0
@export var attack_distance: float = 160.0
@export var push_apart_force: float = 100.0
@export var wanted_enemy_distance: float = 80.0
@export var knockback_accel: float = 700.0
@export var damage: int = 30

var player: Player = null
var knockback: Vector2 = Vector2.ZERO

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurt_box: Area2D = $HurtBox
@onready var hurtable: Hurtable = $Hurtable

func _ready() -> void:
	hurtable.died.connect(func() -> void:
		animation_player.play("death"))

func _physics_process(delta: float) -> void:
	position += knockback * delta
	knockback = knockback.move_toward(Vector2.ZERO, knockback_accel * delta)
	push_apart(delta)
	if hurtable.is_dead:
		return

	if not player:
		var nodes := get_tree().get_nodes_in_group("Player")
		if nodes.is_empty():
			return
		player = nodes[0]
		animation_player.play("idle")

	if player.hurtable.is_dead:
		animation_player.play("idle")
		return

	var player_dir := global_position.direction_to(player.global_position)
	var target_pos := player.global_position - player_dir * wanted_distance
	var player_dist_2 := global_position.distance_squared_to(player.global_position)

	if player_dist_2 > wanted_distance * wanted_distance * 1.1:
		global_position += global_position.direction_to(target_pos) * speed * delta

	rotation = player_dir.angle()

	if player_dist_2 < attack_distance * attack_distance:
		animation_player.play("punch")
	else:
		animation_player.play("run")

func push_apart(delta: float) -> void:
	for node: Node2D in get_tree().get_nodes_in_group("Enemy"):
		if node == self:
			continue
		var dist2 := node.global_position.distance_squared_to(global_position)
		if dist2 > wanted_enemy_distance * wanted_enemy_distance:
			continue
		var dir := node.global_position.direction_to(global_position)
		global_position += (remap(dist2, 0, wanted_enemy_distance * wanted_enemy_distance, 1, 0)
				* dir * push_apart_force * delta)

func hurt() -> void:
	var nodes: Array[Node2D] = hurt_box.get_overlapping_bodies()
	nodes.append_array(hurt_box.get_overlapping_areas())

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")
		h.hurt(damage)
