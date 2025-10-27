extends RefCounted
class_name BodyPoint

enum ConnectionType {
	DIRECT,
	TELEPORT
}

var position: Vector2
var connection_type: ConnectionType

func _init(pos: Vector2, conn_type: ConnectionType = ConnectionType.DIRECT) -> void:
	position = pos
	connection_type = conn_type
