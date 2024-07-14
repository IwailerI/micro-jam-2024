class_name SpellShop
extends CanvasLayer

@export var spell_pool: Array[Spell] = []

@onready var name_right: Label = %NameRight
@onready var icon_right: TextureRect = %IconRight
@onready var description_right: Label = %DescriptionRight
@onready var button_right: Button = %ButtonRight

@onready var name_left: Label = %NameLeft
@onready var icon_left: TextureRect = %IconLeft
@onready var description_left: Label = %DescriptionLeft
@onready var button_left: Button = %ButtonLeft

var left_spell: Spell = null
var right_spell: Spell = null

func _ready() -> void:
	button_left.pressed.connect(func() -> void:
		add_spell(left_spell))
	button_right.pressed.connect(func() -> void:
		add_spell(right_spell))

func start_session() -> void:
	get_tree().paused = true

	var p := get_tree().get_first_node_in_group("Player") as Player

	var spells: Array[Spell] = spell_pool.duplicate()
	for spell: Spell in p.spells:
		spells.erase(spell)

	spells.shuffle()
	assign_spells(spells[0], spells[1])

	show()

func assign_spells(left: Spell, right: Spell) -> void:
	name_left.text = left.name
	icon_left.texture = left.icon
	description_left.text = "%s\n%s\n%s" % [
		left.description,
		"%d maximum water to buy" % left.shop_cost,
		"%d water per use" % left.cost,
	]
	left_spell = left

	name_right.text = right.name
	icon_right.texture = right.icon
	description_right.text = "%s\n%s\n%s" % [
		right.description,
		"%d maximum water to buy" % right.shop_cost,
		"%d water per use" % right.cost,
	]
	right_spell = right

func add_spell(spell: Spell) -> void:
	var p := get_tree().get_first_node_in_group("Player") as Player
	p.spells.push_back(spell)
	p.update_spell_slots()
	p.hurtable.max_health -= spell.shop_cost
	p.hurtable.remove_overheal()
	hide()
	get_tree().paused = false
