extends Node

@onready var IntroPlayer: AudioStreamPlayer = %Intro
@onready var DrumsPlayer: AudioStreamPlayer = %Drums
@onready var LoopPlayer: AudioStreamPlayer = %Loop

func _ready() -> void:
	IntroPlayer.finished.connect(func() -> void:
		LoopPlayer.play()
		DrumsPlayer.play())
	LoopPlayer.finished.connect(func() -> void:
		LoopPlayer.play()
		DrumsPlayer.play())

func _physics_process(_delta: float) -> void:
	if get_tree().get_nodes_in_group("Enemy").is_empty():
		DrumsPlayer.volume_db = -100
	else:
		DrumsPlayer.volume_db = 0
