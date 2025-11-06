extends Area2D
class_name Collectible

var magnetic_strength: float = 10000.0
var pickup_range: float = 80.0
var point_value: int = 1
var magnetic_strength_squared: float = magnetic_strength * magnetic_strength
var pickup_range_squared: float = pickup_range * pickup_range

var velocity: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not is_instance_valid(Game.play_session) or not is_instance_valid(Game.play_session.snake) or not is_instance_valid(Game.play_session.snake.head):
		return

	var head_position: Vector2 = Game.play_session.snake.head.global_position
	var distance_squared: float = head_position.distance_squared_to(global_position)

	# Check if in pickup range
	if distance_squared < pickup_range_squared:
		_pickup()
		return

	# Apply magnetic force (quadratic falloff with distance)
	var magnetic_force: float = magnetic_strength_squared / distance_squared
	var direction: Vector2 = (head_position - global_position).normalized()
	velocity += direction * magnetic_force * delta

	# Apply some damping so velocity doesn't accumulate infinitely
	velocity *= 0.98

	# Move towards player
	global_position += velocity * delta


func _pickup() -> void:
	Game.play_session.score += point_value
	queue_free()
