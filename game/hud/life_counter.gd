extends Control


func _ready() -> void:
	EventBus.snake_health_changed.connect(_update_indicators)


func _update_indicators(current_health: int, max_health: int) -> void:
	var i: int = 0
	for indicator in $HBoxContainer.get_children():
		indicator.visible = (current_health > i)
		i += 1
