extends Area2D
class_name Asteroid

signal asteroid_split(asteroid: Asteroid, pieces: Array[Asteroid])
signal asteroid_destroyed(asteroid: Asteroid)

@export var size: int = 3  ## 1 to 5
@export var enable_wraparound: bool = true
@export var base_speed: float = 50.0
@export var speed_variance: float = 30.0
@export var min_split_pieces: int = 2
@export var max_split_pieces: int = 4
@export var spawn_animation_duration: float = 0.8

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var polygon_points: PackedVector2Array = []
var is_active: bool = false

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var border_line: Line2D = $Border


func _init() -> void:
	modulate.a = 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	_generate_random_polygon()
	_apply_polygon_to_nodes()
	_spawn_animate()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += angular_velocity * delta
	_handle_world_boundary()


func _generate_random_polygon() -> void:
	var num_points = randi_range(6, 10)
	var radius = 50.0 + size * 40.0
	var angle_step = TAU / num_points

	polygon_points.clear()

	for i in range(num_points):
		var angle = angle_step * i + randf_range(-0.2, 0.2)
		var point_radius = radius * randf_range(0.7, 1.3)
		var point = Vector2(cos(angle), sin(angle)) * point_radius
		polygon_points.append(point)


func _apply_polygon_to_nodes() -> void:
	polygon.polygon = polygon_points
	collision_polygon.polygon = polygon_points
	border_line.points = polygon_points


func _handle_world_boundary() -> void:
	var bounds_topleft: Vector2 = Game.play_session.world_bounds_topleft
	var bounds_bottomright: Vector2 = Game.play_session.world_bounds_bottomright

	var crossed = false
	var new_pos = global_position

	if global_position.x > bounds_bottomright.x:
		new_pos.x = bounds_topleft.x
		crossed = true
	elif global_position.x < bounds_topleft.x:
		new_pos.x = bounds_bottomright.x
		crossed = true

	if global_position.y > bounds_bottomright.y:
		new_pos.y = bounds_topleft.y
		crossed = true
	elif global_position.y < bounds_topleft.y:
		new_pos.y = bounds_bottomright.y
		crossed = true

	if crossed:
		if enable_wraparound:
			global_position = new_pos
		else:
			_despawn()


func _despawn() -> void:
	asteroid_destroyed.emit(self)
	queue_free()


func _spawn_collectibles() -> void:
	var collectible_scene: PackedScene = preload("res://gameplay_entities/collectible/collectible.tscn")

	# Spawn 1-3 collectibles based on asteroid size
	var num_collectibles: int = clampi(randi_range(0, size), 1, 3)

	for i in range(num_collectibles):
		var collectible: Collectible = collectible_scene.instantiate()

		# Pick random target position near asteroid
		var angle: float = randf() * TAU
		var distance: float = randf_range(80.0, 150.0)
		var target_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		# Initially spawn at center of asteroid
		collectible.global_position = global_position
		collectible.scale = Vector2.ZERO
		add_sibling(collectible)

		# Animate to target position
		var tween: Tween = collectible.create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(collectible, "global_position", target_pos, 0.5)
		tween.tween_property(collectible, "scale", Vector2.ONE, 0.5)


func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid and is_active:
		take_damage()


func _on_body_entered(body: Node2D) -> void:
	if body is SnakeHead:
		body.take_damage(1)
		take_damage()


func take_damage() -> void:
	var impact_fx_scene: PackedScene = preload("res://gameplay_entities/asteroid/asteroid_impact_fx.tscn")
	var impact_fx = impact_fx_scene.instantiate()
	impact_fx.position = position
	add_sibling(impact_fx)
	_spawn_collectibles()
	if size <= 1: _despawn()
	else:         split()


func split() -> void:
	var pieces: Array[Asteroid] = []
	
	# Determine how to split
	var remaining_size = size - 1
	var num_pieces = _calculate_split_count(remaining_size)
	
	# Generate split sizes
	var split_sizes = _generate_split_sizes(remaining_size, num_pieces)
	
	# Create each piece
	for piece_size in split_sizes:
		var piece: Asteroid = _create_split_piece(piece_size)
		pieces.append(piece)
		piece.animate_velocity_after_splitting()
	
	# Emit signal
	asteroid_split.emit(self, pieces)
	
	# Destroy this asteroid
	queue_free()


func animate_velocity_after_splitting() -> void:
	var target_velocity: Vector2 = velocity
	var target_angular_velocity: float = angular_velocity
	velocity *= 5.0
	angular_velocity *= 5.0
	var tween := create_tween()
	tween.set_parallel(true).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "velocity", target_velocity, 2.0)
	tween.tween_property(self, "angular_velocity", target_angular_velocity, 2.0)


func _calculate_split_count(remaining_size: int) -> int:
	if remaining_size == 1:
		return randi_range(1, 2)
	else:
		return randi_range(min_split_pieces, max_split_pieces)


func _generate_split_sizes(total_size: int, num_pieces: int) -> Array[int]:
	var sizes: Array[int] = []
	
	# Start with all pieces at size 1
	for i in range(num_pieces):
		sizes.append(1)
	
	# Distribute remaining size randomly
	var remaining = total_size - num_pieces
	while remaining > 0:
		var index = randi() % num_pieces
		sizes[index] += 1
		remaining -= 1

	return sizes


func _create_split_piece(piece_size: int) -> Asteroid:
	var asteroid_scene = load("res://gameplay_entities/asteroid/asteroid.tscn") as PackedScene
	var piece = asteroid_scene.instantiate() as Asteroid
	
	piece.size = piece_size
	piece.enable_wraparound = enable_wraparound
	piece.spawn_animation_duration = 0.3
	
	# Position near parent with random offset
	var offset_angle = randf() * TAU
	var offset_distance = 50.0
	piece.global_position = global_position + Vector2(cos(offset_angle), sin(offset_angle)) * offset_distance

	# Set velocity away from center
	var direction = Vector2(cos(offset_angle), sin(offset_angle))
	var speed_multiplier = 1.0 / max(piece_size, 1)
	var speed = (base_speed + randf_range(-speed_variance, speed_variance)) * speed_multiplier * 1.5  # Slightly faster after split
	piece.velocity = direction * speed
	piece.angular_velocity = randf_range(-1, 1)

	# Add to scene
	add_sibling(piece)

	return piece


func _spawn_animate() -> void:
	is_active = false
	
	# Start transparent and scaled up
	modulate.a = 0.0
	scale = Vector2(1.2, 1.2)
	
	# Tween to normal values
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, spawn_animation_duration)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), spawn_animation_duration)
	
	# When animation completes, activate collision after 2 physics frames
	# (we wait for 2 physics frames to prevent collision with asteroids that are already inside this asteroid since spawning)
	await tween.finished
	for i in 2: if is_inside_tree(): await get_tree().physics_frame
	is_active = true
