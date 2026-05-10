class_name StatusEffect
extends RefCounted

enum StatusType {
	SLOW,
	BURN,
	POISON,
}

enum StackPolicy {
	REFRESH,
	STRONGEST,
	REPLACE,
	STACK,
	INDEPENDENT,
}

var status_type: int
var source_tower_id: String
var duration_seconds: float
var remaining_seconds: float
var move_speed_multiplier: float
var tick_interval_seconds: float
var tick_damage: float
var tick_elapsed_seconds: float
var attack_type: int
var damage_school: int
var stack_policy: int


func _init(
	new_status_type: int,
	new_source_tower_id: String,
	new_duration_seconds: float,
	new_move_speed_multiplier: float = 1.0,
	new_tick_interval_seconds: float = 0.0,
	new_tick_damage: float = 0.0,
	new_attack_type: int = DamageTypes.AttackType.MAGIC,
	new_damage_school: int = DamageTypes.DamageSchool.PHYSICAL,
	new_stack_policy: int = StackPolicy.REFRESH
) -> void:
	assert(new_status_type >= 0, "Status type must be valid.")
	assert(not new_source_tower_id.is_empty(), "Source tower id is required.")
	assert(new_duration_seconds >= 0.0, "Status duration cannot be negative.")
	assert(new_move_speed_multiplier > 0.0, "Move speed multiplier must be positive.")
	assert(new_tick_interval_seconds >= 0.0, "Tick interval cannot be negative.")
	assert(new_tick_damage >= 0.0, "Tick damage cannot be negative.")

	status_type = new_status_type
	source_tower_id = new_source_tower_id
	duration_seconds = new_duration_seconds
	remaining_seconds = duration_seconds
	move_speed_multiplier = new_move_speed_multiplier
	tick_interval_seconds = new_tick_interval_seconds
	tick_damage = new_tick_damage
	tick_elapsed_seconds = 0.0
	attack_type = new_attack_type
	damage_school = new_damage_school
	stack_policy = new_stack_policy


func is_dot() -> bool:
	return tick_interval_seconds > 0.0 and tick_damage > 0.0


func refresh_from(other: StatusEffect) -> void:
	assert(other != null, "Status effect is required.")

	source_tower_id = other.source_tower_id
	duration_seconds = other.duration_seconds
	remaining_seconds = other.duration_seconds
	move_speed_multiplier = other.move_speed_multiplier
	tick_interval_seconds = other.tick_interval_seconds
	tick_damage = other.tick_damage
	tick_elapsed_seconds = 0.0
	attack_type = other.attack_type
	damage_school = other.damage_school
	stack_policy = other.stack_policy
