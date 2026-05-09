class_name TowerConfig
extends RefCounted


func get_stats(tower_type: GameTower.Type, tier: int) -> TowerStats:
	assert(tier >= 1, "Tower tier must be at least 1.")

	var base_stats := _get_base_stats(tower_type)
	return TowerStats.new(
		base_stats.damage * float(tier),
		base_stats.range_cells + 0.25 * float(tier - 1),
		base_stats.attack_interval,
		base_stats.splash_radius_cells,
		base_stats.slow_multiplier,
		base_stats.slow_duration + _slow_duration_bonus(tower_type, tier),
		base_stats.targeting
	)


func _get_base_stats(tower_type: GameTower.Type) -> TowerStats:
	match tower_type:
		GameTower.Type.SINGLE_TARGET:
			return TowerStats.new(10.0, 2.5, 1.0)
		GameTower.Type.AREA:
			return TowerStats.new(6.0, 2.0, 1.4, 0.75)
		GameTower.Type.SLOW:
			return TowerStats.new(3.0, 2.25, 1.2, 0.0, 0.6, 1.5)

	assert(false, "Unsupported tower type.")
	return TowerStats.new(0.0, 1.0, 1.0)


func _slow_duration_bonus(tower_type: GameTower.Type, tier: int) -> float:
	if tower_type != GameTower.Type.SLOW:
		return 0.0

	return 0.25 * float(tier - 1)
