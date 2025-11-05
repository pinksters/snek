extends Area2D
class_name Projectile

@export var speed: float = 1500.0

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_check_world_bounds()


func _check_world_bounds() -> void:
	var bounds_topleft: Vector2 = Game.play_session.world_bounds_topleft
	var bounds_bottomright: Vector2 = Game.play_session.world_bounds_bottomright

	if global_position.x < bounds_topleft.x or global_position.x > bounds_bottomright.x or \
	   global_position.y < bounds_topleft.y or global_position.y > bounds_bottomright.y:
		_despawn()


func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid:
		area.take_damage()
		_despawn()


func initialize(pos: Vector2, dir: Vector2) -> void:
	global_position = pos
	direction = dir.normalized()
	rotation = dir.angle()


func _despawn() -> void:
	set_physics_process(false)
	speed = 0
	collision_layer = 0
	collision_mask = 0
	$Visual.hide()
	$CPUParticles2D.emitting = false
	await create_tween().tween_interval(0.5).finished # Give particles enough time to dissipate before deleting the projectile
	queue_free()
