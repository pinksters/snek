extends Control
class_name AmmoCounter

const AMMO_INDICATOR_SCENE = preload("res://hud/ammo_indicator.tscn")

@onready var ammo_container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	EventBus.snake_ammo_changed.connect(_on_ammo_changed)


func _on_ammo_changed(current_ammo: float, max_ammo: int) -> void:
	_ensure_indicators(max_ammo)

	for i in range(max_ammo):
		var indicator: AmmoIndicator = ammo_container.get_child(i)

		if i < floor(current_ammo):     # Fully filled
			indicator.fill_amount = 100.0
		elif i == floor(current_ammo):  # Partially filled
			indicator.fill_amount = current_ammo - floor(current_ammo)
		else:                           # Empty
			indicator.fill_amount = 0.0


## Ensure matching amount of ammo indicators
func _ensure_indicators(count: int) -> void:
	var current_count = ammo_container.get_child_count()

	# Add indicators if needed
	while current_count < count:
		var indicator = AMMO_INDICATOR_SCENE.instantiate()
		ammo_container.add_child(indicator)
		current_count += 1

	# Remove indicators if needed
	while current_count > count:
		var child = ammo_container.get_child(current_count - 1)
		ammo_container.remove_child(child)
		child.queue_free()
		current_count -= 1
