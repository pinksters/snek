@tool
extends Control

@export var movement_radius: float = 5.0
@export var movement_speed: float = 1.0
@export var chaos_scale: float = 0.5

var time_offset: float = 0.0
var label_offsets: Array[float] = []


func _ready():
	# Generate random time offsets for each label to make them move independently
	for i in range(get_child_count()):
		label_offsets.append(randf() * 1000.0)
	time_offset = randf() * 1000.0


func _process(delta):
	var time = Time.get_ticks_msec() / 1000.0 * movement_speed

	for i in range(get_child_count()):
		var label = get_child(i)
		if label is Label:
			# Use different noise samples for x and y, plus unique offset per label
			var noise_x = sin((time + label_offsets[i]) * chaos_scale) * cos((time + label_offsets[i] * 1.3) * chaos_scale * 0.7)
			var noise_y = cos((time + label_offsets[i] * 1.7) * chaos_scale) * sin((time + label_offsets[i] * 0.9) * chaos_scale * 1.1)

			# Apply movement within the radius
			label.position.x = noise_x * movement_radius
			label.position.y = noise_y * movement_radius
