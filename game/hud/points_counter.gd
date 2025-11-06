extends Control
class_name PointsCounter

@onready var points_label: Label = $HBoxContainer/PointsLabel


func _ready() -> void:
	points_label.text = "0"
	EventBus.score_changed.connect(_on_score_changed)


func _on_score_changed(_old_score: int, new_score: int) -> void:
	points_label.text = str(new_score)
