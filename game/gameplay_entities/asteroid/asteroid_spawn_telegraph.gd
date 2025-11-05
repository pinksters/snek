extends Node2D
class_name AsteroidSpawnTelegraph

## Visual telegraph that warns where an asteroid will spawn

signal telegraph_complete

@export var telegraph_duration: float = 1.5  ## Time to complete telegraph
@export var inner_radius: float = 100.0  ## Radius of filling circle
@export var outer_radius: float = 120.0  ## Radius of rotating arc
@export var fill_color: Color = Color(1.0, 0.4, 0.2, 0.6)
@export var arc_color: Color = Color(1.0, 0.6, 0.3, 0.8)
@export var arc_width: float = 4.0

var elapsed_time: float = 0.0
var is_complete: bool = false


func _ready() -> void:
	z_index = 100  # Draw on top


func _process(delta: float) -> void:
	if is_complete:
		return

	elapsed_time += delta
	var progress = elapsed_time / telegraph_duration

	if progress >= 1.0:
		progress = 1.0
		is_complete = true
		telegraph_complete.emit()
		queue_free()

	queue_redraw()


func _draw() -> void:
	var progress = clampf(elapsed_time / telegraph_duration, 0.0, 1.0)

	# Draw filling circle (grows from center)
	var fill_radius = inner_radius * progress
	if fill_radius > 0:
		draw_circle(Vector2.ZERO, fill_radius, fill_color)

	# Draw outer ring (background)
	draw_arc(Vector2.ZERO, outer_radius, 0, TAU, 32, arc_color * Color(1, 1, 1, 0.3), arc_width)

	# Draw rotating arc (clockwise, grows from 0 to TAU)
	var arc_angle = progress * TAU
	if arc_angle > 0:
		draw_arc(Vector2.ZERO, outer_radius, -PI / 2, -PI / 2 + arc_angle, 32, arc_color, arc_width)
