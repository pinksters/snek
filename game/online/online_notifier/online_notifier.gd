extends CanvasLayer

@onready var notification_container: VBoxContainer = $VBoxContainer

var active_notifications: Dictionary = {}
var next_notification_id: int = 0


func _ready() -> void:
	ScoreServer.score_submitted.connect(_on_score_submitted)


func create_score_submission_notification() -> int:
	var notification_id = next_notification_id
	next_notification_id += 1

	var notification = preload("res://online/online_notifier/score_notification.tscn").instantiate()
	notification_container.add_child(notification)
	active_notifications[notification_id] = notification

	return notification_id


func _on_score_submitted(success: bool, game_id: int, message: String) -> void:
	var latest_id: int = -1
	for id in active_notifications.keys():
		if id > latest_id:
			latest_id = id

	if latest_id >= 0 and active_notifications.has(latest_id):
		var notification = active_notifications[latest_id]
		if is_instance_valid(notification):
			notification.on_submission_complete(success, game_id, message)
		active_notifications.erase(latest_id)
