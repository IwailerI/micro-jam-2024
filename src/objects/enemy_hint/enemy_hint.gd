class_name EnemyHint
extends Node2D

var player: Player = null
var target: Node2D = null

func process_targets(targets: Array[Node2D]) -> void:
	assert(not targets.is_empty())

	if not target:
		target = targets[0]

	var dist := global_position.distance_to(target.global_position)
	for candidate: Node2D in targets:
		var c_dist := global_position.distance_to(candidate.global_position)
		if c_dist * 1.15 < dist:
			dist = c_dist
			target = candidate
	
	_set_hint((target.global_position - global_position).angle())

func _set_hint(azimuth: float) -> void:
	if self.visible:
		var from := fposmod(rotation, 2 * PI)
		var to := fposmod(azimuth, 2 * PI)
		if absf(from - to) > PI:
			if from < to:
				to -= 2 * PI
			else:
				from -= 2 * PI
		rotation = from
		create_tween().tween_property(self, "rotation", to, 0.5)
	else:
		show()
		modulate = Color.TRANSPARENT
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.5)
		rotation = azimuth

func stop() -> void:
	if visible:
		var t := create_tween()
		t.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
		t.chain().tween_callback(hide)

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	global_position = player.global_position