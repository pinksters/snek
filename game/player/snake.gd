extends Node2D
class_name Snake

signal snake_damaged(health: int)

@onready var head: SnakeHead = $SnakeHead
@onready var body: SnakeBody = $SnakeBody


func _ready() -> void:
	Game.play_session.snake = self
	head.position_updated.connect(_on_head_position_updated)
	head.head_damaged.connect(_on_head_damaged)
	head.head_died.connect(_on_head_died)


func _physics_process(_delta: float) -> void:
	if body.check_collision_with_head(head.position + head.current_direction * 40.0):
		head.take_damage(1)


func _on_head_position_updated(new_position: Vector2, is_teleport: bool) -> void:
	body.add_head_position(new_position, is_teleport)


func _on_head_damaged(amount: int) -> void:
	snake_damaged.emit(head.get_health())


func _on_head_died() -> void:
	Game.end_play_session()


func grow(amount: int = 1) -> void:
	body.modify_length(amount)


func shrink(amount: int = 1) -> void:
	body.modify_length(-amount)


func get_length() -> int:
	return body.get_body_length()


func get_health() -> int:
	return head.get_health()


func teleport_snake(new_position: Vector2) -> void:
	head.teleport_to(new_position)
