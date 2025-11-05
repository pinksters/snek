# Displays headwear on a character based on what's equipped on-chain
extends Node2D

# { hat_name: hat_sprite_file_path }
var supported_hats: Dictionary[String, String] = {
	"Hawaiian Hat": "res://player/headwear/hat_sprites/hat_hawaiian.png",
	"Cowboy Hat": "res://player/headwear/hat_sprites/hat_cowboy.png",
	"Bucket Hat": "res://player/headwear/hat_sprites/hat_bucket.png",
	"Traffic Cone": "res://player/headwear/hat_sprites/hat_traffic_cone.png"
}

func _ready() -> void:
	var equipped_hat: NFT = PolkaGodot.equipped_nft
	
	if is_instance_valid(equipped_hat) and supported_hats.keys().has(equipped_hat.name):
		var hat_texture: Texture2D = load(supported_hats[equipped_hat.name])
		$Sprite2D.texture = hat_texture
	else:
		$Sprite2D.texture = null
