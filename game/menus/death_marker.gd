extends Node2D

@onready var x_shape: Node2D = $XShape

func _ready() -> void:
	scale = Vector2.ZERO

func animate_appear() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)

	# Bounce scale animation from 0 to 1
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(30), 0.2)
	await tween.finished
	
	# Fade out while rotating faster
	var fade_out_tween = create_tween()
	fade_out_tween.set_trans(Tween.TRANS_CUBIC)
	fade_out_tween.set_parallel(true)
	fade_out_tween.tween_property(self, "rotation", deg_to_rad(-360), 1.3)
	fade_out_tween.tween_property(self, "modulate:a", 0.0, 1.3)
