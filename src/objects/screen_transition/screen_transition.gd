extends CanvasLayer

signal transition_finished

@onready var anim: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	call_deferred("transition_out")

func is_in_transition() -> bool:
	return anim.is_playing()

func transition_out() -> void:
	anim.play("transition_out")
	await anim.animation_finished
	hide()
	transition_finished.emit()

func do_transition(loader: Callable) -> void:
	show()
	get_tree().paused = true
	anim.play("transition_in")
	await anim.animation_finished
	await loader.call()
	anim.play("transition_out")
	await anim.animation_finished
	get_tree().paused = false
	hide()
	transition_finished.emit()

func change_scene_to_packed(packed: PackedScene) -> void:
	await do_transition(func() -> void:
		get_tree().change_scene_to_packed(packed))
