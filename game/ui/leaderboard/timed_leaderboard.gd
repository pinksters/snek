## Fetches and displays top scores for the current competition period

extends PanelContainer
class_name TimedLeaderboard

@export_group("Configuration")
@export var limit: int = 10
@export var auto_refresh_on_ready: bool = true
@export var auto_refresh_interval_sec: float = 30.0

@onready var scroll_container = %ScrollContainer
@onready var entries_container = %EntriesContainer
@onready var loading_label = %LoadingLabel
@onready var empty_state_label = %EmptyStateLabel
@onready var error_label = %ErrorLabel
@onready var refresh_button = %RefreshButton
@onready var next_reward_label = %NextRewardLabel
@onready var progress_bar = %ProgressBar

var is_loading: bool = false
var current_results: Array = []
var current_period_info: Dictionary = {}
var leaderboard_entry_scene: PackedScene = preload("res://ui/leaderboard/leaderboard_entry.tscn")

var auto_refresh_timer: float = 0.0
var next_reward_time: float = 0.0


func _ready():
	ScoreServer.current_period_leaderboard_fetched.connect(_on_leaderboard_fetched)
	ScoreServer.fetch_failed.connect(_on_fetch_failed)
	
	refresh_button.pressed.connect(refresh_leaderboard)
	if auto_refresh_on_ready:
		refresh_leaderboard()


func _process(delta):
	if auto_refresh_interval_sec > 0:
		auto_refresh_timer += delta
		if auto_refresh_timer >= auto_refresh_interval_sec:
			auto_refresh_timer = 0.0
			refresh_leaderboard()
	
	_update_reward_timer(delta)


func refresh_leaderboard():
	if is_loading:
		return
	
	_show_loading_state()
	_fetch_leaderboard()


func _fetch_leaderboard():
	is_loading = true
	ScoreServer.fetch_current_period_leaderboard(limit)


func _on_leaderboard_fetched(results: Array, period_info: Dictionary):
	is_loading = false
	current_results = results
	current_period_info = period_info
	
	_display_results(results)
	_hide_loading_state()
	
	if period_info.has("nextReward"):
		_parse_next_reward_time(period_info["nextReward"])


func _on_fetch_failed(error: String):
	is_loading = false
	_show_error_state(error)


func _display_results(results: Array):
	_clear_entries()

	if results.size() == 0:
		_show_empty_state()
		return
	
	for i in range(results.size()):
		var result = results[i]
		if result is not Dictionary:
			push_error("Leaderboard entry data is not a Dictionary, skipping")
			continue
		
		var rank = i + 1
		var address = result.get("address", "Unknown")
		var score = result.get("bestScore", 0)
		var hat_type = result.get("hatType", "")
		
		var entry = leaderboard_entry_scene.instantiate()
		entries_container.add_child(entry)
		
		entry.set_entry_data(rank, address, score, hat_type)
		
		if address == PolkaGodot.current_address:
			entry.highlight_player(true)


func _clear_entries():
	for child in entries_container.get_children():
		child.queue_free()


func _show_loading_state():
	scroll_container.visible = false
	loading_label.visible = true
	empty_state_label.visible = false
	error_label.visible = false


func _hide_loading_state():
	loading_label.visible = false
	scroll_container.visible = true


func _show_empty_state():
	scroll_container.visible = false
	empty_state_label.visible = true
	error_label.visible = false


func _show_error_state(error: String):
	_clear_entries()

	scroll_container.visible = false
	loading_label.visible = false
	empty_state_label.visible = false
	error_label.visible = true
	error_label.text = "Error: " + error


func _parse_next_reward_time(next_reward_iso: String):
	var datetime = Time.get_datetime_dict_from_datetime_string(next_reward_iso, false)
	next_reward_time = Time.get_unix_time_from_datetime_dict(datetime)


func _update_reward_timer(delta: float) -> void:
	if next_reward_time <= 0:
		return
	
	var current_time: float = Time.get_unix_time_from_system()
	var time_remaining = max(next_reward_time - current_time, 0.0)
	
	# Update label with human-readable time
	var hours = int(time_remaining / 3600)
	var minutes = int((time_remaining - hours * 3600) / 60)
	var seconds = int(time_remaining) % 60
	next_reward_label.text = "Next reward in: %02d:%02d:%02d" % [hours, minutes, seconds]

	# Update progress bar
	if current_period_info.has("intervalHours"):
		var interval_seconds = current_period_info["intervalHours"] * 3600.0
		var elapsed = interval_seconds - time_remaining
		var progress = elapsed / interval_seconds if interval_seconds > 0 else 0
		progress_bar.value = clamp(progress, 0.0, 1.0)
