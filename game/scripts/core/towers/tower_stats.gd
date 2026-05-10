class_name TowerStats
extends RefCounted

enum Targeting {
	FIRST,
	LOWEST_HEALTH,
	NEAREST,
}

var damage: float
var range_cells: float
var attack_interval: float
var weapon_type: int
var attack_type: int
var damage_school: int
var attack_pattern: int
var splash_radius_cells: float
var slow_multiplier: float
var slow_duration: float
var status_type: int
var status_duration: float
var status_move_speed_multiplier: float
var status_tick_interval: float
var status_tick_damage: float
var status_stack_policy: int
var targeting: Targeting
var effects: Array
var projectile_speed_cells_per_second: float
var projectile_hit_radius_cells: float


func _init(
	new_damage: float,
	new_range_cells: float,
	new_attack_interval: float,
	new_weapon_type: int = DamageTypes.WeaponType.CROSSBOW,
	new_attack_type: int = DamageTypes.AttackType.PIERCE,
	new_damage_school: int = DamageTypes.DamageSchool.PHYSICAL,
	new_attack_pattern: int = DamageTypes.AttackPattern.SINGLE_PROJECTILE,
	new_splash_radius_cells: float = 0.0,
	new_slow_multiplier: float = 1.0,
	new_slow_duration: float = 0.0,
	new_status_type: int = -1,
	new_status_duration: float = 0.0,
	new_status_move_speed_multiplier: float = 1.0,
	new_status_tick_interval: float = 0.0,
	new_status_tick_damage: float = 0.0,
	new_status_stack_policy: int = -1,
	new_targeting: Targeting = Targeting.FIRST,
	new_effects: Array = [],
	new_projectile_speed_cells_per_second: float = 6.0,
	new_projectile_hit_radius_cells: float = 0.12
) -> void:
	assert(new_damage >= 0.0, "Tower damage cannot be negative.")
	assert(new_range_cells > 0.0, "Tower range must be positive.")
	assert(new_attack_interval > 0.0, "Tower attack interval must be positive.")
	assert(new_splash_radius_cells >= 0.0, "Tower splash radius cannot be negative.")
	assert(new_slow_multiplier > 0.0, "Tower slow multiplier must be positive.")
	assert(new_slow_duration >= 0.0, "Tower slow duration cannot be negative.")
	assert(new_status_duration >= 0.0, "Tower status duration cannot be negative.")
	assert(new_status_move_speed_multiplier > 0.0, "Tower status move speed multiplier must be positive.")
	assert(new_status_tick_interval >= 0.0, "Tower status tick interval cannot be negative.")
	assert(new_status_tick_damage >= 0.0, "Tower status tick damage cannot be negative.")
	assert(new_projectile_speed_cells_per_second > 0.0, "Tower projectile speed must be positive.")
	assert(new_projectile_hit_radius_cells >= 0.0, "Tower projectile hit radius cannot be negative.")

	damage = new_damage
	range_cells = new_range_cells
	attack_interval = new_attack_interval
	weapon_type = new_weapon_type
	attack_type = new_attack_type
	damage_school = new_damage_school
	attack_pattern = new_attack_pattern
	splash_radius_cells = new_splash_radius_cells
	slow_multiplier = new_slow_multiplier
	slow_duration = new_slow_duration
	status_type = new_status_type
	status_duration = new_status_duration
	status_move_speed_multiplier = new_status_move_speed_multiplier
	status_tick_interval = new_status_tick_interval
	status_tick_damage = new_status_tick_damage
	status_stack_policy = new_status_stack_policy
	targeting = new_targeting
	effects = _duplicate_effects(new_effects)
	projectile_speed_cells_per_second = new_projectile_speed_cells_per_second
	projectile_hit_radius_cells = new_projectile_hit_radius_cells


func has_status_effect() -> bool:
	return status_type >= 0 and status_duration > 0.0


func has_effect_type(effect_type: int) -> bool:
	for candidate in effects:
		var effect := candidate as TowerEffect
		if effect != null and effect.effect_type == effect_type:
			return true

	return false


static func _duplicate_effects(source_effects: Array) -> Array:
	var result := []
	for candidate in source_effects:
		var effect := candidate as TowerEffect
		if effect != null:
			result.append(effect.duplicate_effect())

	return result
