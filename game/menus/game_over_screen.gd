extends Control

func _ready() -> void:
	$GameOverTextureRect.texture = Game.play_session.game_over_screenshot
	$RetryButton.pressed.connect(Game.start_play_session)
	$MainMenuButton.pressed.connect(Game.to_main_menu)
	$ScoreLabel.text = str(Game.play_session.score)
