class_name DeathParticles
extends Node2D

func _ready() -> void:
	for child: Node in get_children():
		var p := child as CPUParticles2D
		if p:
			p.emitting = true

static func do(node: Node2D) -> void:
	var inst: Node2D = preload ("death_particles.tscn").instantiate()
	inst.global_position = node.global_position
	node.get_parent().add_child(inst)
