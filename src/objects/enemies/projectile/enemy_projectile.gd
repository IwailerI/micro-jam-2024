extends Area2D

const SPEED: float = 300.0

@export var damage: int = 30

var velocity: Vector2 = Vector2.ZERO

func _ready():
	$LifeTimer.timeout.connect(queue_free)
	area_entered.connect(inflict_damage)
	body_entered.connect(inflict_damage)

func _physics_process(delta):
	if velocity == Vector2.ZERO:
		var player := get_tree().get_first_node_in_group("Player")
		if not player:
			queue_free()
			return
		velocity = global_position.direction_to(player.global_position) * SPEED
	global_position += velocity * delta

func inflict_damage(node):
	if not node.is_in_group(Hurtable.GROUP):
		return
	var h: Hurtable = node.get_node("Hurtable")
	h.hurt(damage)
	queue_free()
