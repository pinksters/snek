@tool
extends Sprite2D

@export var spin_speed: float = 1.0

func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
