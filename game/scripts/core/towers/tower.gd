class_name GameTower
extends RefCounted

enum Type {
	SINGLE_TARGET,
	AREA,
	SLOW,
}

var id: String
var tower_type: Type
var tier: int
var grid_position: Vector2i
var cooldown_remaining: float


func _init(
	new_id: String,
	new_type: Type,
	new_tier: int,
	new_grid_position: Vector2i = Vector2i.ZERO
) -> void:
	assert(not new_id.is_empty(), "Tower id is required.")
	assert(new_tier >= 1, "Tower tier must be at least 1.")

	id = new_id
	tower_type = new_type
	tier = new_tier
	grid_position = new_grid_position
	cooldown_remaining = 0.0
