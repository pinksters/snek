extends Node2D

@export var bounds_topleft_marker: Marker2D = null
@export var bounds_bottomright_marker: Marker2D = null

func _ready() -> void:
	Game.play_session.world_bounds_topleft = bounds_topleft_marker.global_position
	Game.play_session.world_bounds_bottomright = bounds_bottomright_marker.global_position
