extends Node2D
class_name CoinPickupMessage

@export var score_value: int = 1
@export var float_distance: float = 80.0
@export var animation_duration: float = 1.5

@onready var label: Label = $Label


func _ready() -> void:
	label.text = "+" + str(score_value)
	
	var target_position: Vector2 = position + Vector2(0, -float_distance)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, animation_duration)
	tween.tween_property(label, "modulate:a", 0.0, animation_duration)
	
	tween.finished.connect(queue_free)
