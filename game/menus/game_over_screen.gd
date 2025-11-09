extends Control

@onready var texture_rect: TextureRect = $GameOverTextureRect
@onready var ui_panel: PanelContainer = $UIPanel
@onready var orbiting_dots: Node2D = $UIPanel/DecorativeCorners/OrbitingDots
@onready var score_label: Label = $UIPanel/VBoxContainer/ScoreLabel
@onready var retry_button: Button = $UIPanel/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $UIPanel/VBoxContainer/MainMenuButton

var death_marker_scene = preload("res://menus/death_marker.tscn")
var floating_text_scene = preload("res://menus/game_over_floating_text.tscn")

func _ready() -> void:
	# Set up the screenshot texture and animate the transition shader
	texture_rect.texture = Game.play_session.game_over_screenshot
	setup_shockwave_shader()

	# Connect buttons
	retry_button.pressed.connect(Game.start_play_session)
	main_menu_button.pressed.connect(Game.to_main_menu)

	# Display score
	score_label.text = str(Game.play_session.score)

	# Start the UI animation sequence
	start_animation_sequence()


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
			texture_rect.material.set_shader_parameter("edge_width", value),
		0.0,
		0.2,
		1.0
	)
	tween.tween_method(
		func(value: float):
			texture_rect.material.set_shader_parameter("progress", value),
		0.0,
		1.0,
		3.0
	)


func start_animation_sequence() -> void:
	# Convert UV position to screen coordinates
	var viewport_size = get_viewport_rect().size
	var death_screen_pos = Game.play_session.game_over_player_position * viewport_size

	# Spawn death marker and "game over" text at player's death position
	spawn_death_marker(death_screen_pos)
	spawn_floating_text(death_screen_pos)

	# Show UI panel after a delay
	await get_tree().create_timer(1.5).timeout
	animate_ui_panel_appearance()
	animate_orbiting_dots()


func spawn_death_marker(position: Vector2) -> void:
	var death_marker = death_marker_scene.instantiate()
	add_child(death_marker)
	death_marker.position = position
	death_marker.animate_appear()


func spawn_floating_text(position: Vector2) -> void:
	var floating_text = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.position = position + Vector2(0, -80)

	await get_tree().create_timer(0.2).timeout
	floating_text.animate_appear()


func animate_ui_panel_appearance() -> void:
	var panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(ui_panel, "modulate:a", 1.0, 0.5)


func animate_orbiting_dots() -> void:
	var orbit_tween = create_tween()
	orbit_tween.set_loops()
	orbit_tween.set_ease(Tween.EASE_IN_OUT)
	orbit_tween.set_trans(Tween.TRANS_SINE)

	# Rotate the dots around the center continuously
	orbit_tween.tween_property(orbiting_dots, "rotation", TAU, 8.0).from(0.0)

	for i in range(orbiting_dots.get_child_count()):
		var dot = orbiting_dots.get_child(i)
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.set_ease(Tween.EASE_IN_OUT)
		pulse_tween.set_trans(Tween.TRANS_SINE)
		
		pulse_tween.tween_property(dot, "scale", Vector2(1.4, 1.4), 0.8).set_delay(i * 0.3)
		pulse_tween.tween_property(dot, "scale", Vector2.ONE, 0.8)
