class_name GameTower
extends RefCounted

enum Type {
	SINGLE_TARGET,
	AREA,
	SLOW,
	FLAME,
}

var id: String
var tower_type: Type
var tier: int
var grid_position: Vector2i
var cooldown_remaining: float
var invested_gold: int


func _init(
	new_id: String,
	new_type: Type,
	new_tier: int,
	new_grid_position: Vector2i = Vector2i.ZERO,
	new_invested_gold: int = 0
) -> void:
	assert(not new_id.is_empty(), "Tower id is required.")
	assert(new_tier >= 1, "Tower tier must be at least 1.")
	assert(new_invested_gold >= 0, "Invested gold cannot be negative.")

	id = new_id
	tower_type = new_type
	tier = new_tier
	grid_position = new_grid_position
	cooldown_remaining = 0.0
	invested_gold = new_invested_gold
