extends Node2D

signal wave_completed

const WIN_SCREEN := preload ("res://src/scenes/win_screen/win_screen.tscn")

@export var spawn_distance: float = 1200.0
@export var waves: Array[SpawnWave]

@onready var spawn_node: Node2D = %Spawned
@onready var shop: SpellShop = %Shop
@onready var spawn_timer: Timer = %SpawnTimer

var is_wave_in_progress: bool = false
var enemies_to_spawn: Array[PackedScene]
var current_wave: int = 0
var player: Player = null

func _ready() -> void:
	wave_completed.connect(shop.start_session)

	spawn_timer.timeout.connect(spawn_enemy)

	call_deferred("deferred_ready")

func deferred_ready() -> void:
	if ScreenTransition.is_in_transition():
		await ScreenTransition.transition_finished
	
	start_wave()

func _physics_process(_delta: float) -> void:
	if not is_wave_in_progress:
		return

	if enemies_to_spawn.is_empty() and get_tree().get_nodes_in_group("WaveEnemy").is_empty():
		is_wave_in_progress = false
		await get_tree().create_timer(1.0).timeout
		wave_completed.emit()
		await get_tree().create_timer(2.0).timeout
		start_wave()

func spawn_enemy() -> void:
	if enemies_to_spawn.is_empty() or not is_wave_in_progress:
		spawn_timer.stop()
		return
	var enemy: Node2D = (enemies_to_spawn.pop_back() as PackedScene).instantiate()

	spawn_node.add_child(enemy)
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		assert(player, "spawning impossible, player not found")
	var random_direction := Vector2.from_angle(randf_range(0, 2 * PI))
	enemy.global_position = player.global_position + random_direction * spawn_distance

func start_wave() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		assert(player, "starting wave impossible, player not found")

	if current_wave >= waves.size():
		var inst := WIN_SCREEN.instantiate()
		inst.call("hydrate", player.hurtable.health)
		ScreenTransition.do_transition(change_scene_to_instance.bind(inst))
		return
	current_wave += 1
	is_wave_in_progress = true
	enemies_to_spawn = waves[current_wave - 1].generate_enemy_sequence()
	spawn_timer.start(0.6 - 0.1 * current_wave)

func change_scene_to_instance(inst: Node) -> void:
	var t := get_tree()
	t.current_scene.queue_free()
	t.current_scene.get_parent().remove_child(t.current_scene)
	t.root.add_child(inst)
	t.current_scene = inst