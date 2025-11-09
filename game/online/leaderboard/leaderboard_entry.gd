## Displays a single player's entry of the leaderboard

extends PanelContainer
class_name LeaderboardEntry

@onready var rank_label: Label = $MarginContainer/HBoxContainer/RankLabel
@onready var avatar_container: Control = $MarginContainer/HBoxContainer/AvatarContainer
@onready var wallet_label: Label = $MarginContainer/HBoxContainer/WalletLabel
@onready var score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var headwear_node: HeadwearDisplay = %Headwear


func set_entry_data(rank: int, wallet_address: String, score_value: int, hat_id: String = ""):
	rank_label.text = str(rank)
	wallet_label.text = _truncate_address(wallet_address)
	score_label.text = str(score_value)
	headwear_node.show_hat(hat_id)


func _truncate_address(address: String) -> String:
	if address.length() <= 10:
		return address
	return address.substr(0, 6) + "..." + address.substr(address.length() - 4, 4)


func highlight_player(is_current_player: bool):
	if is_current_player:  self_modulate = Color(1.2, 1.2, 0.8) 
	else:                  self_modulate = Color.WHITE
