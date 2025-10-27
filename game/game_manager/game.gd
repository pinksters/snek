extends Node

var play_session: PlaySession = null


func start_play_session() -> void:
	play_session = PlaySession.new()
	get_tree().change_scene_to_file("res://play_area/play_area.tscn")
