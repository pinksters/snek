## Individual score submission notification that manages its own lifecycle
extends PanelContainer

@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar

enum State {
	SUBMITTING,
	SUCCESS,
	FAILURE
}

var current_state: State = State.SUBMITTING
var fade_timer: float = 0.0
var celebration_timer: float = 0.0

const FADE_IN_DURATION = 0.3
const CELEBRATION_DURATION = 1.5
const FADE_OUT_DURATION = 0.5

const COLOR_SUBMITTING = Color(0.15, 0.2, 0.35, 0.95)
const COLOR_SUBMITTING_BORDER = Color(0.3, 0.4, 0.6, 1)
const COLOR_SUCCESS = Color(0.12, 0.5, 0.12, 0.95)
const COLOR_SUCCESS_BORDER = Color(0.3, 0.8, 0.3, 1)
const COLOR_FAILURE = Color(0.5, 0.12, 0.12, 0.95)
const COLOR_FAILURE_BORDER = Color(0.9, 0.3, 0.3, 1)


func _ready() -> void:
	modulate.a = 0.0
	set_state(State.SUBMITTING)


func _process(delta: float) -> void:
	match current_state:
		State.SUBMITTING:
			_process_fade_in(delta)
		State.SUCCESS, State.FAILURE:
			_process_celebration(delta)


func _process_fade_in(delta: float) -> void:
	if modulate.a < 1.0:
		fade_timer += delta
		modulate.a = min(1.0, fade_timer / FADE_IN_DURATION)


func _process_celebration(delta: float) -> void:
	celebration_timer += delta

	# Fade out after celebration
	if celebration_timer > CELEBRATION_DURATION:
		var fade_progress = (celebration_timer - CELEBRATION_DURATION) / FADE_OUT_DURATION
		modulate.a = 1.0 - fade_progress
		
		if modulate.a <= 0.0:
			queue_free()
	else:
		# Pulse effect during celebration
		var pulse = 0.85 + 0.15 * sin(celebration_timer * 10.0)
		modulate.a = pulse


func set_state(state: State) -> void:
	current_state = state

	match state:
		State.SUBMITTING:
			label.text = "Submitting score on-chain..."
			_apply_panel_style(COLOR_SUBMITTING, COLOR_SUBMITTING_BORDER, false)
			progress_bar.visible = true
		State.SUCCESS:
			label.text = "Score submitted successfully!"
			_apply_panel_style(COLOR_SUCCESS, COLOR_SUCCESS_BORDER, true)
			progress_bar.visible = false
			celebration_timer = 0.0
		State.FAILURE:
			label.text = "Score submission failed"
			_apply_panel_style(COLOR_FAILURE, COLOR_FAILURE_BORDER, true)
			progress_bar.visible = false
			celebration_timer = 0.0


func _apply_panel_style(bg_color: Color, border_color: Color, add_glow: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color

	# Border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color

	# Rounded corners
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	# Shadow for depth
	style.shadow_size = 6
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_offset = Vector2(0, 3)

	# Add glow effect for success/failure states
	if add_glow:
		style.shadow_size = 8
		var glow_color = border_color
		glow_color.a = 0.6
		style.shadow_color = glow_color
		style.shadow_offset = Vector2(0, 0)

	add_theme_stylebox_override("panel", style)


func on_submission_complete(success: bool, game_id: int, message: String) -> void:
	if success:
		set_state(State.SUCCESS)
	else:
		set_state(State.FAILURE)
		label.text = "Failed: %s" % message
