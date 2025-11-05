extends Control

func _ready() -> void:
	$PlayButton.pressed.connect(Game.start_play_session)
