extends Node

var play_session: PlaySession = null


func start_play_session() -> void:
	play_session = PlaySession.new()
	get_tree().change_scene_to_file("res://gameplay_scene/gameplay_scene.tscn")


func end_play_session() -> void:
	if not play_session.is_active:
		return
	
	play_session.is_active = false
	
	for i in 2: # Wait for all post-gameover visuals to initialize before ending the play session and taking the screenshot of the viewport
		if is_inside_tree(): await get_tree().physics_frame
		if is_inside_tree(): await get_tree().process_frame
	
	# Record last screenshot of the viewport
	var image: Image = get_viewport().get_texture().get_image()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	play_session.game_over_screenshot = texture
	
	# Let ScoreServer submit the game to the server
	ScoreServer.submit_score(play_session)
	
	# Record last position of player in viewport and transition to the game over scene
	play_session.game_over_player_position = (play_session.snake.head.get_global_transform_with_canvas().origin) / Vector2(play_session.snake.get_viewport_rect().size)
	get_tree().change_scene_to_file("res://menus/game_over_screen.tscn")


func to_main_menu() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
