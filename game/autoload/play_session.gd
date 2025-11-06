extends RefCounted
class_name PlaySession

# Entity references
var world_bounds_topleft: Vector2 = Vector2(-INF, -INF)
var world_bounds_bottomright: Vector2 = Vector2(INF, INF)
var snake: Snake = null

# Screenshot of the game taken just before transitioning to the game over screen
var game_over_screenshot: ImageTexture = null
var game_over_player_position: Vector2 = Vector2.ZERO

# Game stats
var score: int = 0:
	set(new_score):
		var old_score: int = score
		score = new_score
		EventBus.score_changed.emit(old_score, new_score)
