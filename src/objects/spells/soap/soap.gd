extends Node2D

var soap := false

func _ready() -> void:
	get_tree().get_first_node_in_group("Player")["soap"] = true
	queue_free()
