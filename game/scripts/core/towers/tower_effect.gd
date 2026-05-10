class_name TowerEffect
extends RefCounted

enum EffectType {
	DAMAGE_PRIMARY,
	SPLASH_DAMAGE,
	APPLY_STATUS,
}

const TYPE_DAMAGE_PRIMARY := "damage_primary"
const TYPE_SPLASH_DAMAGE := "splash_damage"
const TYPE_APPLY_STATUS := "apply_status"

var effect_type: int
var damage_multiplier: float
var radius_cells: float
var status_type: int
var duration: float
var move_speed_multiplier: float
var tick_interval: float
var tick_damage: float
var attack_type: int
var damage_school: int
var stack_policy: int


func _init(
	new_effect_type: int,
	new_damage_multiplier: float = 1.0,
	new_radius_cells: float = 0.0,
	new_status_type: int = -1,
	new_duration: float = 0.0,
	new_move_speed_multiplier: float = 1.0,
	new_tick_interval: float = 0.0,
	new_tick_damage: float = 0.0,
	new_attack_type: int = -1,
	new_damage_school: int = -1,
	new_stack_policy: int = -1
) -> void:
	assert(new_effect_type >= 0, "Tower effect type must be valid.")
	assert(new_damage_multiplier >= 0.0, "Tower effect damage multiplier cannot be negative.")
	assert(new_radius_cells >= 0.0, "Tower effect radius cannot be negative.")
	assert(new_duration >= 0.0, "Tower effect duration cannot be negative.")
	assert(new_move_speed_multiplier > 0.0, "Tower effect movement multiplier must be positive.")
	assert(new_tick_interval >= 0.0, "Tower effect tick interval cannot be negative.")
	assert(new_tick_damage >= 0.0, "Tower effect tick damage cannot be negative.")

	effect_type = new_effect_type
	damage_multiplier = new_damage_multiplier
	radius_cells = new_radius_cells
	status_type = new_status_type
	duration = new_duration
	move_speed_multiplier = new_move_speed_multiplier
	tick_interval = new_tick_interval
	tick_damage = new_tick_damage
	attack_type = new_attack_type
	damage_school = new_damage_school
	stack_policy = new_stack_policy


func duplicate_effect() -> TowerEffect:
	return TowerEffect.new(
		effect_type,
		damage_multiplier,
		radius_cells,
		status_type,
		duration,
		move_speed_multiplier,
		tick_interval,
		tick_damage,
		attack_type,
		damage_school,
		stack_policy
	)


func resolved_attack_type(default_attack_type: int) -> int:
	return default_attack_type if attack_type < 0 else attack_type


func resolved_damage_school(default_damage_school: int) -> int:
	return default_damage_school if damage_school < 0 else damage_school


func resolved_stack_policy() -> int:
	if stack_policy >= 0:
		return stack_policy
	if status_type >= 0:
		return StatusEvent._default_stack_policy(status_type)
	return -1


static func damage_primary(
	new_damage_multiplier: float = 1.0,
	new_attack_type: int = -1,
	new_damage_school: int = -1
) -> TowerEffect:
	return TowerEffect.new(
		EffectType.DAMAGE_PRIMARY,
		new_damage_multiplier,
		0.0,
		-1,
		0.0,
		1.0,
		0.0,
		0.0,
		new_attack_type,
		new_damage_school
	)


static func splash_damage(
	new_radius_cells: float,
	new_damage_multiplier: float = 1.0,
	new_attack_type: int = -1,
	new_damage_school: int = -1
) -> TowerEffect:
	return TowerEffect.new(
		EffectType.SPLASH_DAMAGE,
		new_damage_multiplier,
		new_radius_cells,
		-1,
		0.0,
		1.0,
		0.0,
		0.0,
		new_attack_type,
		new_damage_school
	)


static func apply_status(
	new_status_type: int,
	new_duration: float,
	new_move_speed_multiplier: float = 1.0,
	new_tick_interval: float = 0.0,
	new_tick_damage: float = 0.0,
	new_attack_type: int = -1,
	new_damage_school: int = -1,
	new_stack_policy: int = -1
) -> TowerEffect:
	return TowerEffect.new(
		EffectType.APPLY_STATUS,
		1.0,
		0.0,
		new_status_type,
		new_duration,
		new_move_speed_multiplier,
		new_tick_interval,
		new_tick_damage,
		new_attack_type,
		new_damage_school,
		new_stack_policy
	)
