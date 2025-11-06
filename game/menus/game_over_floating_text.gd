extends Node2D

@onready var label: Label = $Label


func _ready() -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0


func animate_appear() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Scale up while floating upwards
	tween.tween_property(self, "scale", Vector2.ONE, 0.6)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(self, "position:y", position.y - 80, 0.8)
	await tween.finished
	
	# Fade out while still moving upwards
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	fade_out_tween.tween_property(self, "position:y", position.y - 80, 0.8)
	fade_out_tween.tween_property(self, "modulate:a", 0.0, 0.8)
