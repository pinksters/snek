extends Node2D

var target_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

func _physics_process(delta: float) -> void:
	position = lerp(position, target_position, delta * 10.0)
	rotation = lerp_angle(rotation, target_rotation, delta * 10.0)
