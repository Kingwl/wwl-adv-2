extends GutTest


func test_single_target_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.SINGLE_TARGET, 1)

	assert_eq(stats.damage, 10.0)
	assert_eq(stats.range_cells, 2.5)
	assert_eq(stats.attack_interval, 1.0)
	assert_eq(stats.weapon_type, DamageTypes.WeaponType.CROSSBOW)
	assert_eq(stats.attack_type, DamageTypes.AttackType.PIERCE)
	assert_eq(stats.damage_school, DamageTypes.DamageSchool.PHYSICAL)
	assert_eq(stats.attack_pattern, DamageTypes.AttackPattern.SINGLE_PROJECTILE)
	assert_eq(stats.splash_radius_cells, 0.0)
	assert_eq(stats.slow_multiplier, 1.0)
	assert_eq(stats.slow_duration, 0.0)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)
	assert_eq(stats.projectile_speed_cells_per_second, 6.0)
	assert_eq(stats.projectile_hit_radius_cells, 0.12)
	assert_eq(stats.effects.size(), 1)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.DAMAGE_PRIMARY)


func test_default_tower_config_loads_json_tower_definitions() -> void:
	var definitions := TowerConfig.load_definitions_from_path(TowerConfig.DEFAULT_TOWER_DEFINITION_PATH)
	var config := TowerConfig.new(definitions)

	assert_eq(config.get_tower_types(), [
		GameTower.Type.SINGLE_TARGET,
		GameTower.Type.AREA,
		GameTower.Type.SLOW,
		GameTower.Type.FLAME,
		GameTower.Type.POISON,
	])
	assert_eq(config.get_tower_id(GameTower.Type.SINGLE_TARGET), "single")
	assert_eq(config.get_tower_id(GameTower.Type.FLAME), "flame")
	assert_eq(config.get_display_name(GameTower.Type.POISON), "Poison")
	assert_eq(config.get_description(GameTower.Type.POISON), "Toxic DoT")
	assert_eq(config.get_tower_button_node_name(GameTower.Type.POISON), "PoisonTowerButton")
	assert_eq(config.get_tower_button_specs().size(), 5)
	assert_true(config.is_visual_test_enabled(GameTower.Type.SLOW))
	assert_eq(config.get_visual_test_tower_specs().size(), 5)
	assert_eq(config.get_build_cost(GameTower.Type.SINGLE_TARGET), 25)
	assert_eq(
		config.get_tower_texture_path(GameTower.Type.SINGLE_TARGET),
		"res://assets/sprites/towers/round_rotating/single.png"
	)
	assert_eq(config.get_projectile_texture_paths(GameTower.Type.POISON).size(), 4)
	assert_eq(config.get_impact_texture_paths(GameTower.Type.POISON).size(), 4)


func test_tower_definition_parser_normalizes_raw_json_data() -> void:
	var definitions := TowerDefinitionParser.definitions_from_dictionary({
		"towers": [
			{
				"id": "flame",
				"type": "FLAME",
				"display_name": "Flame",
				"description": "Burn DoT",
				"build_cost": 33,
				"weapon_type": "SPELL",
				"attack_type": "MAGIC",
				"damage_school": "FIRE",
				"attack_pattern": "STATUS_DOT",
				"visual_test_enabled": true,
				"visuals": {
					"tower": "res://custom/flame.png",
					"projectiles": ["res://custom/flame_projectile.png"],
					"impacts": ["res://custom/flame_impact.png"],
				},
				"projectile": {
					"speed_cells_per_second": 5.5,
					"hit_radius_cells": 0.2,
				},
				"tiers": [
					{
						"damage": 4.0,
						"range_cells": 2.0,
						"attack_interval": 1.0,
						"effects": [
							{
								"type": "apply_status",
								"status_type": "BURN",
								"duration": 3.0,
								"tick_interval": 1.0,
								"tick_damage": 2.0,
								"stack_policy": "REFRESH",
							},
						],
					},
				],
			},
		],
	})

	var definition := definitions[GameTower.Type.FLAME] as Dictionary
	var tier := (definition["tiers"] as Array)[0] as Dictionary
	var effect := (tier["effects"] as Array)[0] as Dictionary

	assert_eq(definition["build_cost"], 33)
	assert_eq(definition["weapon_type"], DamageTypes.WeaponType.SPELL)
	assert_eq(definition["attack_type"], DamageTypes.AttackType.MAGIC)
	assert_eq(definition["damage_school"], DamageTypes.DamageSchool.FIRE)
	assert_eq(definition["attack_pattern"], DamageTypes.AttackPattern.STATUS_DOT)
	assert_eq((definition["visuals"] as Dictionary)["tower"], "res://custom/flame.png")
	assert_eq((definition["projectile"] as Dictionary)["speed_cells_per_second"], 5.5)
	assert_eq(effect["type"], TowerEffect.EffectType.APPLY_STATUS)
	assert_eq(effect["status_type"], StatusEvent.StatusType.BURN)
	assert_eq(effect["status_stack_policy"], StatusEffect.StackPolicy.REFRESH)


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


func test_default_upgrade_tiers_always_increase_damage_and_range() -> void:
	var config := TowerConfig.new()

	for tower_type in config.get_tower_types():
		for tier in range(1, config.get_max_tier(tower_type)):
			var current := config.get_stats(tower_type, tier)
			var next := config.get_stats(tower_type, tier + 1)

			assert_gt(next.damage, current.damage)
			assert_gt(next.range_cells, current.range_cells)


func test_upgrade_preview_includes_required_damage_and_range_growth() -> void:
	var config := TowerConfig.new()

	assert_eq(
		config.get_upgrade_preview(GameTower.Type.SINGLE_TARGET, 1),
		"Damage +8 / Range +0.25"
	)
	assert_eq(config.get_upgrade_preview(GameTower.Type.SINGLE_TARGET, 3), "Max tier reached")


func test_area_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.AREA, 1)

	assert_eq(stats.damage, 6.0)
	assert_eq(stats.range_cells, 2.0)
	assert_eq(stats.attack_interval, 1.4)
	assert_eq(stats.weapon_type, DamageTypes.WeaponType.CANNON)
	assert_eq(stats.attack_type, DamageTypes.AttackType.SIEGE)
	assert_eq(stats.damage_school, DamageTypes.DamageSchool.PHYSICAL)
	assert_eq(stats.attack_pattern, DamageTypes.AttackPattern.SPLASH_PROJECTILE)
	assert_eq(stats.splash_radius_cells, 0.75)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)
	assert_eq(stats.projectile_speed_cells_per_second, 4.5)
	assert_eq(stats.effects.size(), 1)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.SPLASH_DAMAGE)
	assert_eq(stats.effects[0].radius_cells, 0.75)


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
	assert_eq(stats.weapon_type, DamageTypes.WeaponType.SPELL)
	assert_eq(stats.attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(stats.damage_school, DamageTypes.DamageSchool.FROST)
	assert_eq(stats.attack_pattern, DamageTypes.AttackPattern.STATUS_PROJECTILE)
	assert_eq(stats.slow_multiplier, 0.6)
	assert_eq(stats.slow_duration, 1.5)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)
	assert_eq(stats.projectile_speed_cells_per_second, 5.25)
	assert_eq(stats.effects.size(), 2)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.DAMAGE_PRIMARY)
	assert_eq(stats.effects[1].effect_type, TowerEffect.EffectType.APPLY_STATUS)
	assert_eq(stats.effects[1].status_type, StatusEvent.StatusType.SLOW)
	assert_eq(stats.effects[1].move_speed_multiplier, 0.6)


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


func test_flame_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.FLAME, 1)

	assert_eq(stats.damage, 4.0)
	assert_eq(stats.range_cells, 2.2)
	assert_eq(stats.attack_interval, 1.25)
	assert_eq(stats.weapon_type, DamageTypes.WeaponType.SPELL)
	assert_eq(stats.attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(stats.damage_school, DamageTypes.DamageSchool.FIRE)
	assert_eq(stats.attack_pattern, DamageTypes.AttackPattern.STATUS_DOT)
	assert_eq(stats.status_type, StatusEvent.StatusType.BURN)
	assert_eq(stats.status_duration, 3.0)
	assert_eq(stats.status_tick_interval, 1.0)
	assert_eq(stats.status_tick_damage, 2.0)
	assert_eq(stats.status_stack_policy, StatusEffect.StackPolicy.REFRESH)
	assert_eq(stats.targeting, TowerStats.Targeting.FIRST)
	assert_eq(stats.projectile_speed_cells_per_second, 5.0)
	assert_eq(stats.effects.size(), 2)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.DAMAGE_PRIMARY)
	assert_eq(stats.effects[1].effect_type, TowerEffect.EffectType.APPLY_STATUS)
	assert_eq(stats.effects[1].status_type, StatusEvent.StatusType.BURN)
	assert_eq(stats.effects[1].tick_interval, 1.0)
	assert_eq(stats.effects[1].tick_damage, 2.0)


func test_flame_upgrade_tiers_improve_damage_range_and_dot_numbers() -> void:
	var config := TowerConfig.new()

	var tier_two := config.get_stats(GameTower.Type.FLAME, 2)
	var tier_three := config.get_stats(GameTower.Type.FLAME, 3)

	assert_eq(config.get_max_tier(GameTower.Type.FLAME), 3)
	assert_eq(config.get_upgrade_cost(GameTower.Type.FLAME, 1), 45)
	assert_eq(config.get_upgrade_cost(GameTower.Type.FLAME, 2), 75)
	assert_eq(tier_two.damage, 7.0)
	assert_eq(tier_two.range_cells, 2.45)
	assert_eq(tier_two.status_duration, 3.5)
	assert_eq(tier_two.status_tick_damage, 3.0)
	assert_eq(tier_three.damage, 11.0)
	assert_eq(tier_three.range_cells, 2.75)
	assert_eq(tier_three.status_duration, 4.0)
	assert_eq(tier_three.status_tick_damage, 4.0)


func test_poison_tier_one_stats() -> void:
	var config := TowerConfig.new()

	var stats := config.get_stats(GameTower.Type.POISON, 1)

	assert_eq(stats.damage, 3.0)
	assert_eq(stats.range_cells, 2.35)
	assert_eq(stats.attack_interval, 1.1)
	assert_eq(stats.weapon_type, DamageTypes.WeaponType.CROSSBOW)
	assert_eq(stats.attack_type, DamageTypes.AttackType.PIERCE)
	assert_eq(stats.damage_school, DamageTypes.DamageSchool.POISON)
	assert_eq(stats.attack_pattern, DamageTypes.AttackPattern.STATUS_DOT)
	assert_eq(stats.status_type, StatusEvent.StatusType.POISON)
	assert_eq(stats.status_duration, 4.0)
	assert_eq(stats.status_tick_interval, 1.0)
	assert_eq(stats.status_tick_damage, 2.0)
	assert_eq(stats.status_stack_policy, StatusEffect.StackPolicy.REFRESH)
	assert_eq(stats.projectile_speed_cells_per_second, 6.4)
	assert_eq(stats.effects.size(), 2)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.DAMAGE_PRIMARY)
	assert_eq(stats.effects[1].effect_type, TowerEffect.EffectType.APPLY_STATUS)
	assert_eq(stats.effects[1].status_type, StatusEvent.StatusType.POISON)
	assert_eq(stats.effects[1].damage_school, DamageTypes.DamageSchool.POISON)


func test_poison_upgrade_tiers_improve_damage_range_and_dot_numbers() -> void:
	var config := TowerConfig.new()

	var tier_two := config.get_stats(GameTower.Type.POISON, 2)
	var tier_three := config.get_stats(GameTower.Type.POISON, 3)

	assert_eq(config.get_max_tier(GameTower.Type.POISON), 3)
	assert_eq(config.get_upgrade_cost(GameTower.Type.POISON, 1), 40)
	assert_eq(config.get_upgrade_cost(GameTower.Type.POISON, 2), 70)
	assert_eq(tier_two.damage, 5.0)
	assert_eq(tier_two.range_cells, 2.6)
	assert_eq(tier_two.status_duration, 4.5)
	assert_eq(tier_two.status_tick_damage, 3.0)
	assert_eq(tier_three.damage, 8.0)
	assert_eq(tier_three.range_cells, 2.9)
	assert_eq(tier_three.status_duration, 5.0)
	assert_eq(tier_three.status_tick_damage, 4.0)


func test_custom_tower_definitions_drive_stats_and_upgrade_cost() -> void:
	var config := TowerConfig.new({
		GameTower.Type.SINGLE_TARGET: {
			"build_cost": 31,
			"visuals": {
				"tower": "res://custom/single.png",
				"projectiles": ["res://custom/projectile.png"],
				"impacts": ["res://custom/impact.png"],
			},
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
				},
			],
		},
	})

	var stats := config.get_stats(GameTower.Type.SINGLE_TARGET, 2)

	assert_eq(config.get_max_tier(GameTower.Type.SINGLE_TARGET), 2)
	assert_eq(config.get_build_cost(GameTower.Type.SINGLE_TARGET), 31)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 1), 9)
	assert_eq(config.get_upgrade_cost(GameTower.Type.SINGLE_TARGET, 2), 0)
	assert_eq(config.get_tower_texture_path(GameTower.Type.SINGLE_TARGET), "res://custom/single.png")
	assert_eq(config.get_projectile_texture_paths(GameTower.Type.SINGLE_TARGET), ["res://custom/projectile.png"])
	assert_eq(config.get_impact_texture_paths(GameTower.Type.SINGLE_TARGET), ["res://custom/impact.png"])
	assert_eq(stats.damage, 4.0)
	assert_eq(stats.range_cells, 2.5)
	assert_eq(stats.attack_interval, 1.5)
	assert_eq(stats.splash_radius_cells, 0.0)
	assert_eq(stats.slow_multiplier, 1.0)
	assert_eq(stats.slow_duration, 0.0)
	assert_eq(stats.effects.size(), 1)
	assert_eq(stats.effects[0].effect_type, TowerEffect.EffectType.DAMAGE_PRIMARY)


func test_validate_definitions_rejects_damage_or_range_not_increasing() -> void:
	var errors := TowerConfig.validate_definitions({
		GameTower.Type.SINGLE_TARGET: {
			"tiers": [
				{
					"damage": 5.0,
					"range_cells": 2.0,
					"attack_interval": 1.0,
					"upgrade_cost": 10,
				},
				{
					"damage": 5.0,
					"range_cells": 2.0,
					"attack_interval": 0.9,
				},
			],
		},
	})

	assert_has(errors, "SINGLE_TARGET tier 2 damage must be greater than tier 1.")
	assert_has(errors, "SINGLE_TARGET tier 2 range_cells must be greater than tier 1.")


func test_validate_definitions_rejects_new_splash_or_slow_mechanics_during_upgrade() -> void:
	var errors := TowerConfig.validate_definitions({
		GameTower.Type.SINGLE_TARGET: {
			"tiers": [
				{
					"damage": 5.0,
					"range_cells": 2.0,
					"attack_interval": 1.0,
					"upgrade_cost": 10,
				},
				{
					"damage": 7.0,
					"range_cells": 2.2,
					"attack_interval": 0.9,
					"splash_radius_cells": 0.3,
					"slow_multiplier": 0.8,
					"slow_duration": 1.0,
				},
			],
		},
	})

	assert_has(errors, "SINGLE_TARGET tier 2 cannot add splash to a tower that did not have splash at tier 1.")
	assert_has(errors, "SINGLE_TARGET tier 2 cannot add slow to a tower that did not have slow at tier 1.")
	assert_has(errors, "SINGLE_TARGET tier 2 cannot add status to a tower that did not have status at tier 1.")


func test_validate_definitions_rejects_status_type_change_during_upgrade() -> void:
	var errors := TowerConfig.validate_definitions({
		GameTower.Type.FLAME: {
			"tiers": [
				{
					"damage": 5.0,
					"range_cells": 2.0,
					"attack_interval": 1.0,
					"status_type": StatusEvent.StatusType.BURN,
					"status_duration": 3.0,
					"status_tick_interval": 1.0,
					"status_tick_damage": 2.0,
					"upgrade_cost": 10,
				},
				{
					"damage": 7.0,
					"range_cells": 2.2,
					"attack_interval": 0.9,
					"status_type": StatusEvent.StatusType.POISON,
					"status_duration": 3.0,
					"status_tick_interval": 1.0,
					"status_tick_damage": 2.0,
				},
			],
		},
	})

	assert_has(errors, "FLAME tier 2 cannot change status type from tier 1.")


func test_validate_definitions_rejects_invalid_effects() -> void:
	var errors := TowerConfig.validate_definitions({
		GameTower.Type.AREA: {
			"tiers": [
				{
					"damage": 5.0,
					"range_cells": 2.0,
					"attack_interval": 1.0,
					"effects": [
						{
							"type": TowerEffect.EffectType.SPLASH_DAMAGE,
							"radius_cells": 0.0,
						},
						{
							"type": TowerEffect.EffectType.APPLY_STATUS,
							"status_type": StatusEvent.StatusType.BURN,
							"duration": 3.0,
							"tick_damage": 2.0,
						},
					],
				},
			],
		},
	})

	assert_has(errors, "AREA tier 1 effect 1 radius_cells must be positive for splash_damage.")
	assert_has(errors, "AREA tier 1 effect 2 tick_interval must be positive when tick_damage is positive.")


func test_game_tower_has_runtime_position_and_cooldown_defaults() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)

	assert_eq(tower.grid_position, Vector2i.ZERO)
	assert_eq(tower.cooldown_remaining, 0.0)
	assert_eq(tower.invested_gold, 0)


func test_game_tower_tracks_total_gold_invested() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(1, 2), 25)

	assert_eq(tower.grid_position, Vector2i(1, 2))
	assert_eq(tower.invested_gold, 25)
