extends Node2D

signal wave_completed

@export var spawn_distance: float = 1200.0

@onready var spawn_node: Node2D = %Spawned
@onready var spawn_timer: Timer = %SpawnTimer
@onready var enemy_scenes: Array[PackedScene] = \
[
	preload("res://src/objects/enemies/walker/walker.tscn"),
	preload("res://src/objects/enemies/shooter/shooter.tscn"),
	preload("res://src/objects/enemies/walker/big_walker.tscn"),
	preload("res://src/objects/enemies/shooter/spawner.tscn"),
]

var is_wave_in_progress: bool = true:
	set(v):
		if not is_wave_in_progress and v and current_wave < 5:
			current_wave += 1
			enemies_to_spawn = 30 * current_wave 
var enemies_to_spawn: int = 30
var current_wave: int = 1
var player: Player = null

func _physics_process(_delta: float) -> void:
	if not is_wave_in_progress:
		return
	
	if enemies_to_spawn > 0:
		if not spawn_timer.is_stopped():
			return
		enemies_to_spawn -= 1
		randomize()
		var enemy := enemy_scenes[(randi() % current_wave) & ((randi() % 2) << 1)].instantiate()
		spawn_node.add_child(enemy)
		if not player:
			player = get_tree().get_first_node_in_group("Player")
			assert(player, "Spawning is impossible, player is null")
		var random_direction := Vector2.from_angle(randf_range(0, 2*PI))
		enemy.global_position = player.global_position + random_direction * spawn_distance
		spawn_timer.start(0.6 - 0.1 * current_wave)
		return
	
	if get_tree().get_nodes_in_group("Enemy").is_empty():
		is_wave_in_progress = false
		wave_completed.emit()
