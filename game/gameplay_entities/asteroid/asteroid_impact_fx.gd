extends Node2D

func _ready() -> void:
	$CPUParticles2D.emitting = true
	await create_tween().tween_interval(1.0).finished
	queue_free()
