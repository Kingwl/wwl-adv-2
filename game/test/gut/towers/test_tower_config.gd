extends GutTest


func test_single_target_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.SINGLE_TARGET, 1)

	assert_eq(stats.damage, 10.0)
	assert_eq(stats.range_cells, 2.5)
	assert_eq(stats.attack_interval, 1.0)
	assert_eq(stats.splash_radius_cells, 0.0)
	assert_eq(stats.slow_multiplier, 1.0)
	assert_eq(stats.slow_duration, 0.0)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)


func test_area_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.AREA, 1)

	assert_eq(stats.damage, 6.0)
	assert_eq(stats.range_cells, 2.0)
	assert_eq(stats.attack_interval, 1.4)
	assert_eq(stats.splash_radius_cells, 0.75)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)


func test_slow_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.SLOW, 1)

	assert_eq(stats.damage, 3.0)
	assert_eq(stats.range_cells, 2.25)
	assert_eq(stats.attack_interval, 1.2)
	assert_eq(stats.slow_multiplier, 0.6)
	assert_eq(stats.slow_duration, 1.5)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)


func test_tier_scaling_increases_damage_range_and_slow_duration() -> void:
	var config := TowerConfig.new()

	var single_target_tier_three := config.get_stats(GameTower.Type.SINGLE_TARGET, 3)
	var slow_tier_three := config.get_stats(GameTower.Type.SLOW, 3)

	assert_eq(single_target_tier_three.damage, 30.0)
	assert_eq(single_target_tier_three.range_cells, 3.0)
	assert_eq(single_target_tier_three.attack_interval, 1.0)
	assert_eq(slow_tier_three.damage, 9.0)
	assert_eq(slow_tier_three.range_cells, 2.75)
	assert_eq(slow_tier_three.slow_duration, 2.0)
	assert_eq(slow_tier_three.slow_multiplier, 0.6)


func test_game_tower_has_runtime_position_and_cooldown_defaults() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)

	assert_eq(tower.grid_position, Vector2i.ZERO)
	assert_eq(tower.cooldown_remaining, 0.0)
