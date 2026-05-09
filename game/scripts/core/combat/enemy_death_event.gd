class_name EnemyDeathEvent
extends RefCounted

var enemy_id: String
var reward_gold: int
var source_tower_id: String


func _init(new_enemy_id: String, new_reward_gold: int, new_source_tower_id: String) -> void:
	assert(not new_enemy_id.is_empty(), "Enemy id is required.")
	assert(new_reward_gold >= 0, "Reward gold cannot be negative.")
	assert(not new_source_tower_id.is_empty(), "Source tower id is required.")

	enemy_id = new_enemy_id
	reward_gold = new_reward_gold
	source_tower_id = new_source_tower_id
