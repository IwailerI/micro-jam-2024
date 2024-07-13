extends Walker

@export var projectile_scene: PackedScene
@export var spawn_distance: float = 10.0

func shoot() -> void:
	if stun_left > 0.0:
		return
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			return
	
	var player_dir := global_position.direction_to(player.global_position)
	# var target_pos := player.global_position - player_dir * wanted_distance
	var projectile: Node2D = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + spawn_distance * player_dir
