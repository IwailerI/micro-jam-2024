class_name WaterDrop
extends Area2D

const MAGNETIC_SPEED: float = 400.0
const PICKABLE_DISTANCE: float = 500.0

var player: Player = null
var heal: int = 0

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			print(player)
			queue_free()
			return
	var player_dist_2 := global_position.distance_squared_to(player.global_position)
	if player_dist_2 < PICKABLE_DISTANCE * PICKABLE_DISTANCE:
		var player_dir := global_position.direction_to(player.global_position)
		global_position += player_dir * MAGNETIC_SPEED * delta
