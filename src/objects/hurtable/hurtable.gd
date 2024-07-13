extends Node
class_name Hurtable

signal died
signal revived
signal damage_received(amount: int)
signal heal_received(amount: int)

const GROUP: StringName = &"Hurtable"

## Maximum health of this entity.
@export var max_health: int = 1000

## Current health of this entity. Should not be set directly.
var health: int = 0
## Whether object is dead. Setting this property does nothing.
var is_dead: bool:
    get: return health == 0
    set(v): pass

func _ready() -> void:
    health = max_health
    var parent := get_parent()
    if parent.is_inside_tree() and parent.is_node_ready():
        _assign_group()
    else:
        parent.ready.connect(_assign_group, CONNECT_ONE_SHOT|CONNECT_DEFERRED)

func _assign_group() -> void:
    get_parent().add_to_group(GROUP)

func hurt(amount: int) -> void:
    assert(amount >= 0, "invalid damage amount")
    if amount == 0:
        return
    amount = mini(amount, health)
    var was_dead := is_dead
    health -= amount
    damage_received.emit(amount)
    if not was_dead and is_dead:
        died.emit()

func heal(amount: int, allow_overheal:=false, revive:=false) -> void:
    assert(amount >= 0, "invalid heal amount")
    if amount == 0:
        return
    if is_dead and not revive:
        return
    if not allow_overheal:
        amount = mini(amount, max_health - health)
    var was_dead := is_dead
    health += amount
    if was_dead:
        revived.emit()
    heal_received.emit(amount)

## Kills the entity immediately. Emits only [signal died], 
## not [signal damage_received]
func die() -> void:
    health = 0
    died.emit()