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
var splash_radius_cells: float
var slow_multiplier: float
var slow_duration: float
var targeting: Targeting


func _init(
	new_damage: float,
	new_range_cells: float,
	new_attack_interval: float,
	new_splash_radius_cells: float = 0.0,
	new_slow_multiplier: float = 1.0,
	new_slow_duration: float = 0.0,
	new_targeting: Targeting = Targeting.FIRST
) -> void:
	assert(new_damage >= 0.0, "Tower damage cannot be negative.")
	assert(new_range_cells > 0.0, "Tower range must be positive.")
	assert(new_attack_interval > 0.0, "Tower attack interval must be positive.")
	assert(new_splash_radius_cells >= 0.0, "Tower splash radius cannot be negative.")
	assert(new_slow_multiplier > 0.0, "Tower slow multiplier must be positive.")
	assert(new_slow_duration >= 0.0, "Tower slow duration cannot be negative.")

	damage = new_damage
	range_cells = new_range_cells
	attack_interval = new_attack_interval
	splash_radius_cells = new_splash_radius_cells
	slow_multiplier = new_slow_multiplier
	slow_duration = new_slow_duration
	targeting = new_targeting
