class_name GameTower
extends RefCounted

enum Type {
	SINGLE_TARGET,
	AREA,
	SLOW,
	FLAME,
	POISON,
}

var id: String
var tower_type: int
var definition_id: String
var tier: int
var grid_position: Vector2i
var cooldown_remaining: float
var invested_gold: int


func _init(
	new_id: String,
	new_type: int,
	new_tier: int,
	new_grid_position: Vector2i = Vector2i.ZERO,
	new_invested_gold: int = 0,
	new_definition_id: String = ""
) -> void:
	assert(not new_id.is_empty(), "Tower id is required.")
	assert(new_tier >= 1, "Tower tier must be at least 1.")
	assert(new_invested_gold >= 0, "Invested gold cannot be negative.")

	id = new_id
	tower_type = new_type
	definition_id = new_definition_id
	tier = new_tier
	grid_position = new_grid_position
	cooldown_remaining = 0.0
	invested_gold = new_invested_gold


func get_definition_id(tower_config: TowerConfig = null) -> String:
	if not definition_id.is_empty():
		return definition_id
	if tower_config != null:
		var tower_id := tower_config.get_tower_id(tower_type)
		if not tower_id.is_empty():
			return tower_id
	return TowerConfig._tower_type_id(tower_type)
