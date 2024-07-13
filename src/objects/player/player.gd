class_name Player
extends Area2D

@export var speed: float = 200.0
@export var base_attack_damage: int = 100
@export var base_attack_knockback: float = 500.0

var using_dual_stick := false
var is_attacking := false

@onready var hurt_box: Area2D = %HurtBox
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurtable: Hurtable = %Hurtable

func _ready() -> void:
	animation_player.animation_finished.connect(func(_name: StringName) -> void:
		animation_player.play("idle")
		is_attacking=false)
	
	DebugMenu.label(self, func(l: RichTextLabel) -> void:
		l.text="Player Health: %d/%d" % [hurtable.health, hurtable.max_health])

func _physics_process(delta: float) -> void:
	if hurtable.is_dead:
		return

	var input := get_primary_input()

	position += input * speed * delta

	var secondary_input := get_secondary_input()
	rotation = secondary_input.angle()

func _unhandled_input(event: InputEvent) -> void:
	if hurtable.is_dead:
		return

	if event is InputEventMouse:
		# no need to mark the input handled, because it will be used later
		using_dual_stick = false
	elif (
		event.is_action("look_left")
		or event.is_action("look_right")
		or event.is_action("look_down")
		or event.is_action("look_up")
	):
		using_dual_stick = true
	
	if event.is_action_pressed("attack") and not is_attacking:
		animation_player.play("attack")
		is_attacking = true
		
		get_viewport().set_input_as_handled()

func get_primary_input() -> Vector2:
	return Vector2(
		Input.get_axis("movement_left", "movement_right"),
		Input.get_axis("movement_up", "movement_down"),
	).normalized()

func get_secondary_input() -> Vector2:
	if using_dual_stick:
		return Vector2(
			Input.get_axis("look_left", "look_right"),
			Input.get_axis("look_up", "look_down"),
		).normalized()
	else:
		return (get_global_mouse_position() - global_position).normalized()

## Call this method to hurt all entities in player's hurtbox
func hurt() -> void:
	var nodes: Array[Node2D] = hurt_box.get_overlapping_bodies()
	nodes.append_array(hurt_box.get_overlapping_areas())

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		if "knockback" in node and node["knockback"] is Vector2:
			node["knockback"] += (global_position.direction_to(node.global_position)
					* base_attack_knockback)
		var h: Hurtable = node.get_node("Hurtable")
		h.hurt(base_attack_damage)
			