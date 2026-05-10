class_name StatusEvent
extends RefCounted

enum StatusType {
	SLOW,
	BURN,
	POISON,
}

var enemy_id: String
var status_type: int
var duration: float
var multiplier: float
var source_tower_id: String
var tick_interval: float
var tick_damage: float
var attack_type: int
var damage_school: int
var stack_policy: int


func _init(
	new_enemy_id: String,
	new_status_type: int,
	new_duration: float,
	new_multiplier: float,
	new_source_tower_id: String,
	new_tick_interval: float = 0.0,
	new_tick_damage: float = 0.0,
	new_attack_type: int = DamageTypes.AttackType.MAGIC,
	new_damage_school: int = DamageTypes.DamageSchool.PHYSICAL,
	new_stack_policy: int = -1
) -> void:
	assert(not new_enemy_id.is_empty(), "Enemy id is required.")
	assert(new_duration >= 0.0, "Status duration cannot be negative.")
	assert(new_multiplier > 0.0, "Status multiplier must be positive.")
	assert(not new_source_tower_id.is_empty(), "Source tower id is required.")
	assert(new_tick_interval >= 0.0, "Status tick interval cannot be negative.")
	assert(new_tick_damage >= 0.0, "Status tick damage cannot be negative.")

	enemy_id = new_enemy_id
	status_type = new_status_type
	duration = new_duration
	multiplier = new_multiplier
	source_tower_id = new_source_tower_id
	tick_interval = new_tick_interval
	tick_damage = new_tick_damage
	attack_type = new_attack_type
	damage_school = new_damage_school
	stack_policy = _default_stack_policy(new_status_type) if new_stack_policy < 0 else new_stack_policy


static func _default_stack_policy(status_type_value: int) -> int:
	match status_type_value:
		StatusType.SLOW:
			return StatusEffect.StackPolicy.STRONGEST
		_:
			return StatusEffect.StackPolicy.REFRESH
