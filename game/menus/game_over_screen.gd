extends Control

func _ready() -> void:
	$RetryButton.pressed.connect(Game.start_play_session)
	$MainMenuButton.pressed.connect(Game.to_main_menu)
