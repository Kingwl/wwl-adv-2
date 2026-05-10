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


func test_single_target_upgrade_tiers_focus_damage_and_fire_rate() -> void:
	var config := TowerConfig.new()

	var tier_two := config.get_stats(GameTower.Type.SINGLE_TARGET, 2)
	var tier_three := config.get_stats(GameTower.Type.SINGLE_TARGET, 3)

	assert_eq(config.get_max_tier(GameTower.Type.SINGLE_TARGET), 3)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 1), 40)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 2), 70)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 3), 0)
	assert_eq(tier_two.damage, 18.0)
	assert_eq(tier_two.range_cells, 2.75)
	assert_eq(tier_two.attack_interval, 0.9)
	assert_eq(tier_three.damage, 30.0)
	assert_eq(tier_three.range_cells, 3.0)
	assert_eq(tier_three.attack_interval, 0.8)


func test_area_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.AREA, 1)

	assert_eq(stats.damage, 6.0)
	assert_eq(stats.range_cells, 2.0)
	assert_eq(stats.attack_interval, 1.4)
	assert_eq(stats.splash_radius_cells, 0.75)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)


func test_area_upgrade_tiers_expand_splash_and_improve_damage() -> void:
	var config := TowerConfig.new()

	var tier_two := config.get_stats(GameTower.Type.AREA, 2)
	var tier_three := config.get_stats(GameTower.Type.AREA, 3)

	assert_eq(config.get_max_tier(GameTower.Type.AREA), 3)
	assert_eq(config.get_upgrade_cost(GameTower.Type.AREA, 1), 45)
	assert_eq(config.get_upgrade_cost(GameTower.Type.AREA, 2), 75)
	assert_eq(tier_two.damage, 10.0)
	assert_eq(tier_two.range_cells, 2.15)
	assert_eq(tier_two.attack_interval, 1.3)
	assert_eq(tier_two.splash_radius_cells, 0.95)
	assert_eq(tier_three.damage, 16.0)
	assert_eq(tier_three.range_cells, 2.35)
	assert_eq(tier_three.attack_interval, 1.2)
	assert_eq(tier_three.splash_radius_cells, 1.15)


func test_slow_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.SLOW, 1)

	assert_eq(stats.damage, 3.0)
	assert_eq(stats.range_cells, 2.25)
	assert_eq(stats.attack_interval, 1.2)
	assert_eq(stats.slow_multiplier, 0.6)
	assert_eq(stats.slow_duration, 1.5)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)


func test_slow_upgrade_tiers_strengthen_duration_and_multiplier() -> void:
	var config := TowerConfig.new()

	var tier_two := config.get_stats(GameTower.Type.SLOW, 2)
	var tier_three := config.get_stats(GameTower.Type.SLOW, 3)

	assert_eq(config.get_max_tier(GameTower.Type.SLOW), 3)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SLOW, 1), 35)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SLOW, 2), 65)
	assert_eq(tier_two.damage, 5.0)
	assert_eq(tier_two.range_cells, 2.45)
	assert_eq(tier_two.attack_interval, 1.15)
	assert_eq(tier_two.slow_multiplier, 0.55)
	assert_eq(tier_two.slow_duration, 2.0)
	assert_eq(tier_three.damage, 8.0)
	assert_eq(tier_three.range_cells, 2.7)
	assert_eq(tier_three.attack_interval, 1.1)
	assert_eq(tier_three.slow_multiplier, 0.5)
	assert_eq(tier_three.slow_duration, 2.5)


func test_custom_tower_definitions_drive_stats_and_upgrade_cost() -> void:
	var config := TowerConfig.new({
		GameTower.Type.SINGLE_TARGET: {
			"tiers": [
				{
					"damage": 2.0,
					"range_cells": 1.5,
					"attack_interval": 2.0,
					"upgrade_cost": 9,
				},
				{
					"damage": 4.0,
					"range_cells": 2.5,
					"attack_interval": 1.5,
					"splash_radius_cells": 0.25,
					"slow_multiplier": 0.8,
					"slow_duration": 0.75,
				},
			],
		},
	})

	var stats := config.get_stats(GameTower.Type.SINGLE_TARGET, 2)

	assert_eq(config.get_max_tier(GameTower.Type.SINGLE_TARGET), 2)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 1), 9)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 2), 0)
	assert_eq(stats.damage, 4.0)
	assert_eq(stats.range_cells, 2.5)
	assert_eq(stats.attack_interval, 1.5)
	assert_eq(stats.splash_radius_cells, 0.25)
	assert_eq(stats.slow_multiplier, 0.8)
	assert_eq(stats.slow_duration, 0.75)


func test_game_tower_has_runtime_position_and_cooldown_defaults() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)

	assert_eq(tower.grid_position, Vector2i.ZERO)
	assert_eq(tower.cooldown_remaining, 0.0)
	assert_eq(tower.invested_gold, 0)


func test_game_tower_tracks_total_gold_invested() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(1, 2), 25)

	assert_eq(tower.grid_position, Vector2i(1, 2))
	assert_eq(tower.invested_gold, 25)
