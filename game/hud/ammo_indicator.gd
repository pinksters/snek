extends Control
class_name AmmoIndicator

@export var fill_amount: float = 1.0:
	set(value):
		fill_amount = clamp(value, 0.0, 1.0)
		_update_visual()

@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	_update_visual()


func _update_visual() -> void:
	if not progress_bar:
		return
	
	progress_bar.value = fill_amount
	
	if fill_amount >= 1.0:
		progress_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full brightness when fully filled
	elif fill_amount > 0.0:
		progress_bar.modulate = Color(0.7, 0.7, 0.7, 0.9)  # Dimmed while charging
	else:
		progress_bar.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Very dim when empty
