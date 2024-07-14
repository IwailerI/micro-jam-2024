class_name SpawnWave
extends Resource

const WALKER := preload ("res://src/objects/enemies/walker/walker.tscn")
const SHOOTER := preload ("res://src/objects/enemies/shooter/shooter.tscn")
const BIG_WALKER := preload ("res://src/objects/enemies/walker/big_walker.tscn")
const SPAWNER := preload ("res://src/objects/enemies/shooter/spawner.tscn")

@export var walker_count: int = 30
@export var shooter_count: int = 5
@export var big_walker_count: int = 2
@export var spawner_count: int = 1

func generate_enemy_sequence() -> Array[PackedScene]:
	var res: Array[PackedScene] = []
	for _i: int in walker_count: res.push_back(WALKER)
	for _i: int in shooter_count: res.push_back(SHOOTER)
	for _i: int in big_walker_count: res.push_back(BIG_WALKER)
	for _i: int in spawner_count: res.push_back(SPAWNER)
	res.shuffle()
	return res