class_name Player
extends Area2D

const SOAP_MULTIPLIER: float = 1.5
const DEATH_SCREEN := preload ("res://src/scenes/death_screen/death_screen.tscn")

@export var speed: float = 200.0
@export var base_attack_damage: int = 100
@export var base_attack_knockback: float = 500.0
@export var placeholder_spell_icon: Texture

var spells: Array[Spell] = []
var using_dual_stick := false
var is_attacking := false
var queued_spell: Spell = null
var soap := false:
	set(v):
		soap = v
		soap_particles.emitting = v

@onready var sfx_death: AudioStreamPlayer = %DeathSFX
@onready var sfx_cast: AudioStreamPlayer = %CastSFX
@onready var sfx_hurt: AudioStreamPlayer = %HurtSFX
@onready var sfx_punch: AudioStreamPlayer = %PunchSFX
@onready var water_collectable_area: Area2D = %WaterCollectable
@onready var soap_particles: CPUParticles2D = %SoapParticles
@onready var hurt_box: Area2D = %HurtBox
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hurtable: Hurtable = %Hurtable
@onready var spell_cast_marker: Node2D = %SpellCastPosition
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_bar_text: Label = %HealthLabel
@onready var spell_slots: Array[TextureRect] = [
	%SpellSlot1,
	%SpellSlot2,
	%SpellSlot3,
	%SpellSlot4,
]

func _ready() -> void:
	water_collectable_area.area_entered.connect(func(water_drop: Area2D) -> void:
		hurtable.heal(water_drop["heal"] as int)
		water_drop.queue_free())

	animation_player.animation_finished.connect(func(_name: StringName) -> void:
		animation_player.play("idle")
		is_attacking=false)

	health_bar.max_value = hurtable.max_health
	health_bar.value = hurtable.health
	hurtable.health_changed.connect(update_visual_health)
	hurtable.max_health_changed.connect(func(_v: int) -> void:
		update_visual_health(hurtable.health))
	hurtable.damage_received.connect(func(_v: int) -> void:
		sfx_hurt.play())
	hurtable.died.connect(func() -> void:
		DeathParticles.do(self)
		hide()
		sfx_death.play()
		await sfx_death.finished
		await get_tree().create_timer(0.5).timeout
		ScreenTransition.change_scene_to_packed(DEATH_SCREEN))

	soap = false

	update_spell_slots()

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

func update_visual_health(v: int) -> void:
	var t := health_bar.create_tween()
	health_bar.max_value = hurtable.max_health
	t.set_parallel(true)
	t.tween_property(health_bar, "value", v, 0.2)
	t.tween_property(health_bar, "max_value", hurtable.max_health, 0.2)
	t.tween_method((func(new_v: int) -> void:
			health_bar_text.text="%d/%d" % [new_v, ceili(health_bar.max_value)]),
			health_bar.value, v, 0.2)

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
	sfx_punch.play()
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
	sfx_cast.play()

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

func update_spell_slots() -> void:
	assert(spells.size() <= 4)
	for i: int in 4:
		if spells.size() > i:
			spell_slots[i].texture = spells[i].icon
		else:
			spell_slots[i].texture = placeholder_spell_icon
