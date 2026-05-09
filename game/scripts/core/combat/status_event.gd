class_name StatusEvent
extends RefCounted

enum StatusType {
	SLOW,
}

var enemy_id: String
var status_type: StatusType
var duration: float
var multiplier: float
var source_tower_id: String


func _init(
	new_enemy_id: String,
	new_status_type: StatusType,
	new_duration: float,
	new_multiplier: float,
	new_source_tower_id: String
) -> void:
	assert(not new_enemy_id.is_empty(), "Enemy id is required.")
	assert(new_duration >= 0.0, "Status duration cannot be negative.")
	assert(new_multiplier > 0.0, "Status multiplier must be positive.")
	assert(not new_source_tower_id.is_empty(), "Source tower id is required.")

	enemy_id = new_enemy_id
	status_type = new_status_type
	duration = new_duration
	multiplier = new_multiplier
	source_tower_id = new_source_tower_id
