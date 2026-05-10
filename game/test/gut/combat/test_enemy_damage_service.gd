extends GutTest


func test_basic_enemy_defaults_to_single_mvp_profile() -> void:
	var enemy := Enemy.new("enemy-1")

	assert_eq(enemy.max_health, 20.0)
	assert_eq(enemy.health, 20.0)
	assert_eq(enemy.kill_reward, 5)
	assert_eq(enemy.armor_type, DamageTypes.ArmorType.HEAVY)
	assert_eq(enemy.race_type, DamageTypes.RaceType.BEAST)
	assert_false(enemy.defeated)


func test_apply_damage_events_reduces_enemy_health() -> void:
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var service := EnemyDamageService.new()

	var result := service.apply_damage_events(
		[enemy],
		[DamageEvent.new("enemy-1", 6.0, "tower-a")]
	)

	assert_eq(enemy.health, 14.0)
	assert_false(enemy.defeated)
	assert_eq(result.applied_damage_events.size(), 1)
	assert_eq(result.death_events.size(), 0)
	assert_eq(result.ignored_damage_events.size(), 0)


func test_lethal_damage_marks_enemy_defeated_and_emits_death_event() -> void:
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var service := EnemyDamageService.new()

	var result := service.apply_damage_events(
		[enemy],
		[DamageEvent.new("enemy-1", 25.0, "tower-a")]
	)

	assert_true(enemy.defeated)
	assert_eq(enemy.health, 0.0)
	assert_eq(result.applied_damage_events.size(), 1)
	assert_eq(result.death_events.size(), 1)
	assert_eq(result.death_events[0].enemy_id, "enemy-1")
	assert_eq(result.death_events[0].reward_gold, 5)
	assert_eq(result.death_events[0].source_tower_id, "tower-a")


func test_damage_against_defeated_enemy_is_ignored_without_duplicate_death() -> void:
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var service := EnemyDamageService.new()
	enemy.apply_damage(20.0)

	var result := service.apply_damage_events(
		[enemy],
		[DamageEvent.new("enemy-1", 5.0, "tower-b")]
	)

	assert_true(enemy.defeated)
	assert_eq(enemy.health, 0.0)
	assert_eq(result.applied_damage_events.size(), 0)
	assert_eq(result.death_events.size(), 0)
	assert_eq(result.ignored_damage_events.size(), 1)


func test_apply_damage_events_uses_attack_armor_and_race_affinity() -> void:
	var enemy := Enemy.new(
		"enemy-1",
		1.0,
		40.0,
		5,
		DamageTypes.ArmorType.HEAVY,
		DamageTypes.RaceType.UNDEAD
	)
	var service := EnemyDamageService.new()

	var result := service.apply_damage_events(
		[enemy],
		[DamageEvent.new(
			"enemy-1",
			10.0,
			"tower-a",
			DamageTypes.AttackType.MAGIC,
			DamageTypes.DamageSchool.FIRE
		)]
	)

	assert_eq(enemy.health, 15.0)
	assert_eq(result.applied_damage_events.size(), 1)
	assert_eq(result.applied_damage_events[0].amount, 25.0)
	assert_eq(result.applied_damage_events[0].attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(result.applied_damage_events[0].damage_school, DamageTypes.DamageSchool.FIRE)


func test_damage_for_unknown_enemy_is_ignored() -> void:
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var service := EnemyDamageService.new()

	var result := service.apply_damage_events(
		[enemy],
		[DamageEvent.new("enemy-missing", 5.0, "tower-a")]
	)

	assert_eq(enemy.health, 20.0)
	assert_eq(result.applied_damage_events.size(), 0)
	assert_eq(result.death_events.size(), 0)
	assert_eq(result.ignored_damage_events.size(), 1)
