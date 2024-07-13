class_name Spell
extends Resource

@export var name: String = "Spell"
@export var object: PackedScene

func fire(environment: Node, from: Vector2, direction: Vector2) -> void:
	var instance: Node2D = object.instantiate()
	instance.global_position = from
	instance.rotation = direction.angle()
	environment.add_child(instance)
