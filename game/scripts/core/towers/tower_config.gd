class_name TowerConfig
extends RefCounted

const TIERS_KEY := "tiers"
const DAMAGE_KEY := "damage"
const RANGE_KEY := "range_cells"
const ATTACK_INTERVAL_KEY := "attack_interval"
const SPLASH_RADIUS_KEY := "splash_radius_cells"
const SLOW_MULTIPLIER_KEY := "slow_multiplier"
const SLOW_DURATION_KEY := "slow_duration"
const UPGRADE_COST_KEY := "upgrade_cost"

var tower_definitions: Dictionary


func _init(new_tower_definitions: Dictionary = {}) -> void:
	tower_definitions = (
		_default_tower_definitions()
		if new_tower_definitions.is_empty()
		else new_tower_definitions.duplicate(true)
	)


func get_stats(tower_type: GameTower.Type, tier: int) -> TowerStats:
	var tier_definition := _get_tier_definition(tower_type, tier)
	return TowerStats.new(
		float(tier_definition.get(DAMAGE_KEY, 0.0)),
		float(tier_definition.get(RANGE_KEY, 1.0)),
		float(tier_definition.get(ATTACK_INTERVAL_KEY, 1.0)),
		float(tier_definition.get(SPLASH_RADIUS_KEY, 0.0)),
		float(tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)),
		float(tier_definition.get(SLOW_DURATION_KEY, 0.0)),
		TowerStats.Targeting.FIRST
	)


func get_max_tier(tower_type: GameTower.Type) -> int:
	return _get_tiers(tower_type).size()


func get_upgrade_cost(tower_type: GameTower.Type, tier: int) -> int:
	assert(tier >= 1, "Tower tier must be at least 1.")
	if tier >= get_max_tier(tower_type):
		return 0

	return int(_get_tier_definition(tower_type, tier).get(UPGRADE_COST_KEY, 0))


func can_upgrade(tower: GameTower) -> bool:
	return tower != null and tower.tier < get_max_tier(tower.tower_type)


func _get_tier_definition(tower_type: GameTower.Type, tier: int) -> Dictionary:
	assert(tier >= 1, "Tower tier must be at least 1.")
	var tiers := _get_tiers(tower_type)
	assert(tier <= tiers.size(), "Tower tier is not configured.")
	return tiers[tier - 1] as Dictionary


func _get_tiers(tower_type: GameTower.Type) -> Array:
	assert(tower_definitions.has(tower_type), "Tower type is not configured.")
	var tower_definition := tower_definitions[tower_type] as Dictionary
	var tiers := tower_definition.get(TIERS_KEY, []) as Array
	assert(not tiers.is_empty(), "Tower tiers are required.")
	return tiers


func _default_tower_definitions() -> Dictionary:
	return {
		GameTower.Type.SINGLE_TARGET: {
			TIERS_KEY: [
				_tier(10.0, 2.5, 1.0, 0.0, 1.0, 0.0, 40),
				_tier(18.0, 2.75, 0.9, 0.0, 1.0, 0.0, 70),
				_tier(30.0, 3.0, 0.8),
			],
		},
		GameTower.Type.AREA: {
			TIERS_KEY: [
				_tier(6.0, 2.0, 1.4, 0.75, 1.0, 0.0, 45),
				_tier(10.0, 2.15, 1.3, 0.95, 1.0, 0.0, 75),
				_tier(16.0, 2.35, 1.2, 1.15),
			],
		},
		GameTower.Type.SLOW: {
			TIERS_KEY: [
				_tier(3.0, 2.25, 1.2, 0.0, 0.6, 1.5, 35),
				_tier(5.0, 2.45, 1.15, 0.0, 0.55, 2.0, 65),
				_tier(8.0, 2.7, 1.1, 0.0, 0.5, 2.5),
			],
		},
	}


func _tier(
	damage: float,
	range_cells: float,
	attack_interval: float,
	splash_radius_cells: float = 0.0,
	slow_multiplier: float = 1.0,
	slow_duration: float = 0.0,
	upgrade_cost: int = 0
) -> Dictionary:
	return {
		DAMAGE_KEY: damage,
		RANGE_KEY: range_cells,
		ATTACK_INTERVAL_KEY: attack_interval,
		SPLASH_RADIUS_KEY: splash_radius_cells,
		SLOW_MULTIPLIER_KEY: slow_multiplier,
		SLOW_DURATION_KEY: slow_duration,
		UPGRADE_COST_KEY: upgrade_cost,
	}
