# Displays headwear on a character based on what's equipped on-chain
extends Node2D
class_name HeadwearDisplay

const MODE_AUTOMATIC: int = 0  # Matches the hat equipped by local player 
const MODE_MANUAL: int = 1     # Manual setup by hat name

@export_enum("Automatic", "Manual") var mode: int = 0

# { hat_name: hat_sprite_file_path }
var supported_hats: Dictionary[String, String] = {
	"Hawaiian Hat": "res://player/headwear/hat_sprites/hat_hawaiian.png",
	"Cowboy Hat": "res://player/headwear/hat_sprites/hat_cowboy.png",
	"Bucket Hat": "res://player/headwear/hat_sprites/hat_bucket.png",
	"Traffic Cone": "res://player/headwear/hat_sprites/hat_traffic_cone.png"
}


func _ready() -> void:
	if mode == MODE_AUTOMATIC:
		var equipped_hat: NFT = PolkaGodot.equipped_nft
		if is_instance_valid(equipped_hat):
			show_hat(equipped_hat.name)


func show_hat(hat_name: String = "") -> void:
	if supported_hats.keys().has(hat_name):
		var hat_texture: Texture2D = load(supported_hats[hat_name])
		$Sprite2D.texture = hat_texture
	else:
		$Sprite2D.texture = null
