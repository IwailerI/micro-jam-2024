extends Node

func _ready():
	$Intro.finished.connect(func() -> void:
		$Loop.play()
		$Drums.play())
	$Loop.finished.connect(func() -> void:
		$Loop.play()
		$Drums.play())

func _physics_process(_delta: float) -> void:
	if get_tree().get_nodes_in_group("Enemy").is_empty():
		$Drums.volume_db = -100
	else:
		$Drums.volume_db = 0
