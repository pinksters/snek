extends Line2D
class_name SnakeBody

@export var body_width: float = 40.0
@export var point_spacing: float = 5.0
@export var initial_length: int = 20
@export var routing_padding: float = 400.0

var body_points: Array[BodyPoint] = []
var distance_since_last_point: float = 0.0


func _ready() -> void:
	width = body_width
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND


func add_head_position(head_pos: Vector2, is_teleport: bool = false) -> void:
	# If this is the first point or a teleport, add immediately
	if body_points.is_empty():
		_add_point(head_pos, BodyPoint.ConnectionType.DIRECT)
		return
	if is_teleport:
		_add_point(head_pos, BodyPoint.ConnectionType.TELEPORT)
		distance_since_last_point = 0.0
		return

	# Otherwise, check if we've moved far enough to add a new point
	var last_pos = body_points[0].position
	distance_since_last_point += head_pos.distance_to(last_pos)

	if distance_since_last_point >= point_spacing:
		_add_point(head_pos, BodyPoint.ConnectionType.DIRECT)
		distance_since_last_point = 0.0


func _add_point(pos: Vector2, conn_type: BodyPoint.ConnectionType) -> void:
	var new_point = BodyPoint.new(pos, conn_type)
	body_points.push_front(new_point)

	# Remove old points to limit the length of the snek
	while body_points.size() > initial_length:
		body_points.pop_back()

	_update_visual()


## Updates the points of a Line2D to create the snek's body
func _update_visual() -> void:
	clear_points()

	if not Game.play_session:
		for point in body_points:
			add_point(point.position)
		return

	var bounds_topleft: Vector2 = Game.play_session.world_bounds_topleft
	var bounds_bottomright: Vector2 = Game.play_session.world_bounds_bottomright

	for i in range(body_points.size()):
		var point = body_points[i]

		# Always add the current point
		add_point(point.position)
		
		# Handle teleport connections by routing around the playable area
		if i < body_points.size() - 1 and point.connection_type == BodyPoint.ConnectionType.TELEPORT:
			var prev_point = body_points[i + 1]

			var dx: float = point.position.x - prev_point.position.x
			var dy: float = point.position.y - prev_point.position.y
			print("routing between ", point.position, " and ", prev_point.position)

			# Horizontal teleport (left/right wrap)
			if abs(dx) > abs(dy):
				if dx < 0: # Wrapping from right to left
					add_point(Vector2(bounds_topleft.x - routing_padding, point.position.y))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_bottomright.x + routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_bottomright.x + routing_padding, prev_point.position.y))
					
				else: # Wrapping from left to right
					add_point(Vector2(bounds_bottomright.x + routing_padding, point.position.y))
					add_point(Vector2(bounds_bottomright.x + routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, prev_point.position.y))
			
			# Vertical teleport (top/bottom wrap)
			else:
				if dy > 0: # Wrapping from top to bottom
					add_point(Vector2(point.position.x, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_topleft.y - routing_padding))
					add_point(Vector2(prev_point.position.x, bounds_topleft.y - routing_padding))
				else: # Wrapping from bottom to top
					add_point(Vector2(point.position.x, bounds_topleft.y - routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_topleft.y - routing_padding))
					add_point(Vector2(bounds_topleft.x - routing_padding, bounds_bottomright.y + routing_padding))
					add_point(Vector2(prev_point.position.x, bounds_bottomright.y + routing_padding))


## Check collisions between the head and the body by checking the distance to each of the points.
## Obviously this is much more performant than adding physical collisions for body segments.
func check_collision_with_head(head_pos: Vector2, min_safe_index: int = 5) -> bool:
	# Don't check points too close to the head
	for i in range(min_safe_index, body_points.size()):
		var point = body_points[i]
		if head_pos.distance_to(point.position) < body_width:
			return true
	return false


func modify_length(delta_length: int) -> void:
	initial_length = max(1, initial_length + delta_length)
	
	# If the snake is shrinking (in cold water, I guess) - remove excess points
	while body_points.size() > initial_length:
		body_points.pop_back()
	
	_update_visual()


func get_body_length() -> int:
	return initial_length
