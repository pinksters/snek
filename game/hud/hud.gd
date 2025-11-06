extends CanvasLayer


func _ready() -> void:
	EventBus.snake_health_changed.connect(_update_visibility)


func _update_visibility(current_health: int, _max_health: int) -> void:
	visible = (current_health > 0)
