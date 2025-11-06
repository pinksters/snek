extends Node

var play_session: PlaySession = null


func start_play_session() -> void:
	play_session = PlaySession.new()
	get_tree().change_scene_to_file("res://gameplay_scene/gameplay_scene.tscn")


func end_play_session() -> void:
	# Record last screenshot of the viewport
	var image: Image = get_viewport().get_texture().get_image()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	play_session.game_over_screenshot = texture
	
	get_tree().change_scene_to_file("res://menus/game_over_screen.tscn")


func to_main_menu() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
