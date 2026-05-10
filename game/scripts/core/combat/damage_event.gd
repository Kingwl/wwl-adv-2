class_name DamageEvent
extends RefCounted

var enemy_id: String
var amount: float
var source_tower_id: String
var attack_type: int
var damage_school: int


func _init(
	new_enemy_id: String,
	new_amount: float,
	new_source_tower_id: String,
	new_attack_type: int = DamageTypes.AttackType.CHAOS,
	new_damage_school: int = DamageTypes.DamageSchool.PHYSICAL
) -> void:
	assert(not new_enemy_id.is_empty(), "Enemy id is required.")
	assert(new_amount >= 0.0, "Damage amount cannot be negative.")
	assert(not new_source_tower_id.is_empty(), "Source tower id is required.")

	enemy_id = new_enemy_id
	amount = new_amount
	source_tower_id = new_source_tower_id
	attack_type = new_attack_type
	damage_school = new_damage_school
