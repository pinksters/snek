extends CharacterBody2D
class_name SnakeHead

signal position_updated(new_position: Vector2, is_teleport: bool)
signal head_damaged(damage_amount: int)
signal head_died()

@export var move_speed: float = 200.0
@export var max_health: int = 3
@export var invulnerability_duration: float = 1.0
@export var bounds_teleport_margin: float = 20.0

var current_health: int
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var current_direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shield_sprite: Sprite2D = $Sprite2D/InvincibilityShield


func _ready() -> void:
	current_health = max_health
	sprite.rotation = current_direction.angle() - PI / 2
	_set_visual_invulnerability(false)
	
	# Emit initial signals to initiate HUD
	EventBus.snake_health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	# Handle invulnerability timer
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			_set_visual_invulnerability(false)
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 0:
		current_direction = input_direction
		sprite.rotation = current_direction.angle() - PI / 2
	
	# Move in current direction
	velocity = current_direction * move_speed
	move_and_slide()
	
	var is_teleport: bool = apply_teleports()
	position_updated.emit(position, is_teleport)


# Wraps the snek around the world boundary; returns true if teleported
func apply_teleports() -> bool:
	var bounds_topleft: Vector2 = Game.play_session.world_bounds_topleft
	var bounds_bottomright: Vector2 = Game.play_session.world_bounds_bottomright
	
	if global_position.x >= bounds_bottomright.x    :  global_position.x = bounds_topleft.x + bounds_teleport_margin
	elif global_position.x <= bounds_topleft.x      :  global_position.x = bounds_bottomright.x - bounds_teleport_margin
	elif global_position.y >= bounds_bottomright.y  :  global_position.y = bounds_topleft.y + bounds_teleport_margin
	elif global_position.y <= bounds_topleft.y      :  global_position.y = bounds_bottomright.y - bounds_teleport_margin
	else: return false
	
	return true


func take_damage(amount: int = 1) -> void:
	if is_invulnerable:
		return

	current_health -= amount
	head_damaged.emit(amount)
	EventBus.snake_health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		head_died.emit()
	else:
		_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	invulnerability_timer = invulnerability_duration
	_set_visual_invulnerability(true)


func _set_visual_invulnerability(active: bool) -> void:
	shield_sprite.visible = active


func teleport_to(new_position: Vector2) -> void:
	global_position = new_position
	position_updated.emit(position, true)


func get_health() -> int:
	return current_health


func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
