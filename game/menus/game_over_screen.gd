extends Control

@onready var texture_rect: TextureRect = $GameOverTextureRect

func _ready() -> void:
	texture_rect.texture = Game.play_session.game_over_screenshot
	setup_shockwave_shader()
	
	$RetryButton.pressed.connect(Game.start_play_session)
	$MainMenuButton.pressed.connect(Game.to_main_menu)
	
	$ScoreLabel.text = str(Game.play_session.score)


func setup_shockwave_shader() -> void:
	texture_rect.material.set_shader_parameter("progress", 0.0)
	texture_rect.material.set_shader_parameter("center_uv", Game.play_session.game_over_player_position)
	animate_shockwave()


func animate_shockwave() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_method(
		func(value: float):
			texture_rect.material.set_shader_parameter("progress", value),
		0.0,
		1.0,
		3.0
	)
	tween.tween_method(
		func(value: float):
			texture_rect.material.set_shader_parameter("edge_width", value),
		0.0,
		0.2,
		1.5
	)
