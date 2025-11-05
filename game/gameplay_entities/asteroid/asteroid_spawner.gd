extends Node2D
class_name AsteroidSpawner

## Spawns asteroids periodically in the play area

@export var spawn_interval: float = 2.0  ## Time between spawns
@export var max_asteroids: int = 100  ## Maximum concurrent asteroids
@export var min_size: int = 4  ## Minimum asteroid size
@export var max_size: int = 5  ## Maximum asteroid size
@export var spawn_margin: float = 200.0  ## Minimum distance from world bounds
@export var telegraph_duration: float = 3.0  ## Warning time before spawn

const ASTEROID_SCENE = preload("res://gameplay_entities/asteroid/asteroid.tscn")
const TELEGRAPH_SCENE = preload("res://gameplay_entities/asteroid/asteroid_spawn_telegraph.tscn")

var spawn_timer: float = 0.0
var active_asteroids: Array[Asteroid] = []
var active_telegraphs: Array[AsteroidSpawnTelegraph] = []


func _ready() -> void:
	# Start with a few telegraphed spawns
	for i in range(3):
		_begin_spawn_telegraph()


func _process(delta: float) -> void:
	# Clean up destroyed asteroids and telegraphs from tracking
	active_asteroids = active_asteroids.filter(func(a): return is_instance_valid(a))
	active_telegraphs = active_telegraphs.filter(func(t): return is_instance_valid(t))

	# Begin new spawn telegraphs periodically
	spawn_timer += delta
	if spawn_timer >= spawn_interval and (active_asteroids.size() + active_telegraphs.size()) < max_asteroids:
		_begin_spawn_telegraph()
		spawn_timer = 0.0


func _begin_spawn_telegraph() -> void:
	var spawn_pos = _get_random_spawn_position()
	var size = randi_range(min_size, max_size)
	var initial_velocity = _get_random_velocity()

	# Create telegraph
	var telegraph = TELEGRAPH_SCENE.instantiate() as AsteroidSpawnTelegraph
	telegraph.telegraph_duration = telegraph_duration
	add_child(telegraph)
	telegraph.global_position = spawn_pos

	telegraph.telegraph_complete.connect(_on_telegraph_complete.bind(spawn_pos, initial_velocity, size))
	active_telegraphs.append(telegraph)


func _get_random_spawn_position() -> Vector2:
	var bounds_topleft: Vector2 = Game.play_session.world_bounds_topleft
	var bounds_bottomright: Vector2 = Game.play_session.world_bounds_bottomright

	var min_x = bounds_topleft.x + spawn_margin
	var max_x = bounds_bottomright.x - spawn_margin
	var min_y = bounds_topleft.y + spawn_margin
	var max_y = bounds_bottomright.y - spawn_margin

	return Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)


func _get_random_velocity() -> Vector2:
	var angle = randf() * TAU
	var speed = randf_range(30, 80)
	return Vector2(cos(angle), sin(angle)) * speed


func _on_telegraph_complete(spawn_pos: Vector2, initial_velocity: Vector2, size: int) -> void:
	var asteroid = ASTEROID_SCENE.instantiate() as Asteroid
	asteroid.global_position = spawn_pos
	asteroid.velocity = initial_velocity
	asteroid.size = size
	asteroid.angular_velocity = randf_range(-1, 1)
	add_child(asteroid)

	asteroid.asteroid_destroyed.connect(_on_asteroid_destroyed)
	asteroid.asteroid_split.connect(_on_asteroid_split)

	active_asteroids.append(asteroid)


func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	if asteroid in active_asteroids:
		active_asteroids.erase(asteroid)


func _on_asteroid_split(parent_asteroid: Asteroid, pieces: Array[Asteroid]) -> void:
	if parent_asteroid in active_asteroids:
		active_asteroids.erase(parent_asteroid)
	
	for piece in pieces:
		if is_instance_valid(piece):
			piece.asteroid_destroyed.connect(_on_asteroid_destroyed)
			piece.asteroid_split.connect(_on_asteroid_split)
			active_asteroids.append(piece)
