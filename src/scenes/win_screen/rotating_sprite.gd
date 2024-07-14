extends Sprite2D

@export var turns_per_second: float = 0.5

func _physics_process(delta: float) -> void:
	rotation += 2 * PI * turns_per_second * delta
