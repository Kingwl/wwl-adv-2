class_name EnemyLeakEvent
extends RefCounted

var enemy_id: String
var life_damage: int


func _init(new_enemy_id: String, new_life_damage: int = 1) -> void:
	assert(not new_enemy_id.is_empty(), "Enemy id is required.")
	assert(new_life_damage > 0, "Life damage must be positive.")

	enemy_id = new_enemy_id
	life_damage = new_life_damage
