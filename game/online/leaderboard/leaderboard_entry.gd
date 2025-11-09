## Displays a single player's entry of the leaderboard

extends PanelContainer
class_name LeaderboardEntry

@onready var rank_label: Label = $MarginContainer/HBoxContainer/RankLabel
@onready var avatar_container: Control = $MarginContainer/HBoxContainer/AvatarContainer
@onready var wallet_label: Label = $MarginContainer/HBoxContainer/WalletLabel
@onready var score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var headwear_node: HeadwearDisplay = %Headwear

var is_hovered: bool = false
var is_current_player: bool = false
var current_rank: int = 0
var target_scale: Vector2 = Vector2.ONE
var target_modulate: Color = Color.WHITE
var hover_tween: Tween

const HOVER_SCALE = Vector2(1.02, 1.02)
const HOVER_DURATION = 0.15
const COLOR_NORMAL = Color(0.15, 0.15, 0.2, 0.8)
const COLOR_HOVER = Color(0.22, 0.25, 0.32, 0.95)
const COLOR_PLAYER = Color(0.25, 0.3, 0.15, 0.95)
const COLOR_PLAYER_HOVER = Color(0.3, 0.38, 0.2, 1.0)

# Special colors for top 3 ranks
const COLOR_RANK1 = Color(0.35, 0.28, 0.12, 0.95)  # Gold
const COLOR_RANK1_HOVER = Color(0.45, 0.38, 0.18, 1.0)
const COLOR_RANK2 = Color(0.25, 0.27, 0.3, 0.95)   # Silver
const COLOR_RANK2_HOVER = Color(0.35, 0.37, 0.42, 1.0)
const COLOR_RANK3 = Color(0.3, 0.2, 0.15, 0.95)    # Bronze
const COLOR_RANK3_HOVER = Color(0.4, 0.28, 0.2, 1.0)

const BORDER_NORMAL = Color(0.4, 0.4, 0.5, 1)
const BORDER_HOVER = Color(0.6, 0.65, 0.75, 1)
const BORDER_PLAYER = Color(0.6, 0.75, 0.4, 1)
const BORDER_PLAYER_HOVER = Color(0.75, 0.9, 0.5, 1)

const BORDER_RANK1 = Color(0.9, 0.75, 0.3, 1)      # Gold border
const BORDER_RANK1_HOVER = Color(1.0, 0.85, 0.4, 1)
const BORDER_RANK2 = Color(0.7, 0.75, 0.8, 1)      # Silver border
const BORDER_RANK2_HOVER = Color(0.85, 0.9, 0.95, 1)
const BORDER_RANK3 = Color(0.65, 0.45, 0.3, 1)     # Bronze border
const BORDER_RANK3_HOVER = Color(0.8, 0.6, 0.4, 1)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2.0


func set_entry_data(rank: int, wallet_address: String, score_value: int, hat_id: String = ""):
	current_rank = rank
	rank_label.text = str(rank)
	wallet_label.text = _truncate_address(wallet_address)
	score_label.text = str(score_value)
	headwear_node.show_hat(hat_id)

	# Style rank label for top 3
	if rank == 1:
		rank_label.add_theme_font_size_override("font_size", 28)
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	elif rank == 2:
		rank_label.add_theme_font_size_override("font_size", 24)
		rank_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	elif rank == 3:
		rank_label.add_theme_font_size_override("font_size", 22)
		rank_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))
	else:
		rank_label.remove_theme_font_size_override("font_size")
		rank_label.remove_theme_color_override("font_color")

	_update_appearance()


func _truncate_address(address: String) -> String:
	if address.length() <= 10:
		return address
	return address.substr(0, 6) + "..." + address.substr(address.length() - 4, 4)


func highlight_player(is_current_player_flag: bool):
	is_current_player = is_current_player_flag
	_update_appearance()


func _on_mouse_entered() -> void:
	is_hovered = true
	_update_appearance()


func _on_mouse_exited() -> void:
	is_hovered = false
	_update_appearance()


func _update_appearance() -> void:
	# Cancel existing tween
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Determine target scale
	target_scale = HOVER_SCALE if is_hovered else Vector2.ONE
	hover_tween.tween_property(self, "scale", target_scale, HOVER_DURATION)

	# Determine colors based on state
	var bg_color: Color
	var border_color: Color

	# Check for top 3 ranks first
	if current_rank == 1:
		bg_color = COLOR_RANK1_HOVER if is_hovered else COLOR_RANK1
		border_color = BORDER_RANK1_HOVER if is_hovered else BORDER_RANK1
		target_modulate = Color(1.2, 1.15, 1.0) if is_hovered else Color(1.15, 1.1, 0.95)
	elif current_rank == 2:
		bg_color = COLOR_RANK2_HOVER if is_hovered else COLOR_RANK2
		border_color = BORDER_RANK2_HOVER if is_hovered else BORDER_RANK2
		target_modulate = Color(1.15, 1.15, 1.15) if is_hovered else Color(1.1, 1.1, 1.1)
	elif current_rank == 3:
		bg_color = COLOR_RANK3_HOVER if is_hovered else COLOR_RANK3
		border_color = BORDER_RANK3_HOVER if is_hovered else BORDER_RANK3
		target_modulate = Color(1.15, 1.1, 1.05) if is_hovered else Color(1.1, 1.05, 1.0)
	elif is_current_player:
		bg_color = COLOR_PLAYER_HOVER if is_hovered else COLOR_PLAYER
		border_color = BORDER_PLAYER_HOVER if is_hovered else BORDER_PLAYER
		target_modulate = Color(1.15, 1.15, 0.9) if is_hovered else Color(1.1, 1.1, 0.85)
	else:
		bg_color = COLOR_HOVER if is_hovered else COLOR_NORMAL
		border_color = BORDER_HOVER if is_hovered else BORDER_NORMAL
		target_modulate = Color(1.1, 1.1, 1.1) if is_hovered else Color.WHITE

	# Animate modulate
	hover_tween.tween_property(self, "self_modulate", target_modulate, HOVER_DURATION)

	# Update panel style with new colors
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color

	# Special border width for top 3
	var border_width = 3 if current_rank <= 3 else 2
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color

	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6

	# Add shadow/glow effects
	if current_rank <= 3:
		# Top 3 get a special glow
		style.shadow_size = 6 if is_hovered else 4
		var glow_color = border_color
		glow_color.a = 0.5 if is_hovered else 0.3
		style.shadow_color = glow_color
		style.shadow_offset = Vector2(0, 0)
	elif is_hovered:
		# Regular hover shadow
		style.shadow_size = 4
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_offset = Vector2(0, 2)

	add_theme_stylebox_override("panel", style)
