class_name Spell
extends Resource

@export var name: String = "Spell"
@export var cost: int = 100
@export var shop_cost: int = 100
@export var object: PackedScene
@export var icon: Texture
@export_multiline var description: String = "A powerful spell to conquer your enemies!"

func fire(environment: Node, from: Vector2, direction: Vector2, soap: bool) -> void:
	var instance: Node2D = object.instantiate()
	instance.global_position = from
	instance.rotation = direction.angle()
	if "soap" in instance:
		instance["soap"] = soap
	else:
		push_error("Spell %s does not support soap!" % name)
	environment.add_child(instance)
