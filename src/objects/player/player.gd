class_name Player
extends Area2D

const SOAP_MULTIPLIER: float = 1.5

@export var spells: Array[Spell] = []
@export var speed: float = 200.0
@export var base_attack_damage: int = 100
@export var base_attack_knockback: float = 500.0

var using_dual_stick := false
var is_attacking := false
var queued_spell: Spell = null
var soap := false:
	set(v):
		soap = v
		soap_particles.emitting = v

@onready var water_collectable_area: Area2D = %WaterCollectable
@onready var soap_particles: CPUParticles2D = %SoapParticles
@onready var hurt_box: Area2D = %HurtBox
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurtable: Hurtable = %Hurtable
@onready var spell_cast_marker: Node2D = %SpellCastPosition
@onready var health_bar: ProgressBar = %HealthBar

func _ready() -> void:
	water_collectable_area.area_entered.connect(func(water_drop: Area2D) -> void:
		hurtable.heal(water_drop.heal)
		water_drop.queue_free())
	
	animation_player.animation_finished.connect(func(_name: StringName) -> void:
		animation_player.play("idle")
		is_attacking=false)

	health_bar.max_value = hurtable.max_health
	health_bar.value = hurtable.health
	hurtable.health_changed.connect(func(h: int) -> void:
		var t:=health_bar.create_tween()
		t.tween_property(health_bar, "value", h, 0.2))

	soap = false

	DebugMenu.label(self, func(l: RichTextLabel) -> void:
		l.text="Player Health: %d/%d" % [hurtable.health, hurtable.max_health])

func _physics_process(delta: float) -> void:
	if hurtable.is_dead:
		return

	var input := get_primary_input()

	position += input * speed * delta

	var secondary_input := get_secondary_input()
	rotation = secondary_input.angle()

	if animation_player.current_animation in ["idle", "walk"]:
		if input.is_zero_approx():
			animation_player.play("idle")
		else:
			animation_player.play("walk")

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

	if is_attacking:
		return

	if event.is_action_pressed("attack"):
		animation_player.play("attack")
		is_attacking = true
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("spell_slot_1"):
		queue_spell(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("spell_slot_2"):
		queue_spell(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("spell_slot_3"):
		queue_spell(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("spell_slot_4"):
		queue_spell(3)
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

	var multiplier := SOAP_MULTIPLIER if soap else 1.0

	for node: Node2D in nodes:
		if not node.is_in_group(Hurtable.GROUP):
			continue
		var h: Hurtable = node.get_node("Hurtable")
		h.hurt(ceili(base_attack_damage * multiplier))
		h.knockback((global_position.direction_to(node.global_position) * base_attack_knockback))
	
	soap = false

func queue_spell(slot: int) -> void:
	if spells.size() <= slot:
		return

	queued_spell = spells[slot]
	is_attacking = true
	animation_player.play("spell")

func cast_spell() -> void:
	if not queued_spell:
		return

	var was_soap := soap
	soap = false # we need to reset soap before firing the spell

	queued_spell.fire(
		get_parent(),
		spell_cast_marker.global_position,
		spell_cast_marker.global_position - global_position,
		was_soap,
	)
	hurtable.hurt(queued_spell.cost)
	queued_spell = null
