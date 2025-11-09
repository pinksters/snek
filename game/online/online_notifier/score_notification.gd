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

const COLOR_SUBMITTING = Color(0.2, 0.2, 0.3, 0.9)
const COLOR_SUCCESS = Color(0.1, 0.6, 0.1, 0.9)
const COLOR_FAILURE = Color(0.6, 0.1, 0.1, 0.9)


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
			_apply_panel_color(COLOR_SUBMITTING)
			progress_bar.visible = true
		State.SUCCESS:
			label.text = "Score submitted successfully!"
			_apply_panel_color(COLOR_SUCCESS)
			progress_bar.visible = false
			celebration_timer = 0.0
		State.FAILURE:
			label.text = "Score submission failed"
			_apply_panel_color(COLOR_FAILURE)
			progress_bar.visible = false
			celebration_timer = 0.0


func _apply_panel_color(color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)


func on_submission_complete(success: bool, game_id: int, message: String) -> void:
	if success:
		set_state(State.SUCCESS)
	else:
		set_state(State.FAILURE)
		label.text = "Failed: %s" % message
