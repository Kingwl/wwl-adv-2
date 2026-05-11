extends GutTest


func test_advance_before_spawn_interval_does_not_spawn_enemy() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 2, 1.0, 20.0, 1.0, 5, 20),
	])

	var result := spawner.advance(0.5, [])

	assert_eq(result.spawned_enemies.size(), 0)
	assert_eq(result.wave_clear_events.size(), 0)
	assert_eq(result.current_wave_index, 0)
	assert_false(result.all_waves_cleared)


func test_advance_at_spawn_interval_spawns_configured_enemy() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new(
			"wave-1",
			2,
			1.0,
			24.0,
			1.25,
			6,
			20,
			"armored-undead",
			DamageTypes.ArmorType.LIGHT,
			DamageTypes.RaceType.UNDEAD,
			{
				DamageTypes.DamageSchool.FIRE: -0.25,
			}
		),
	])

	var result := spawner.advance(1.0, [])
	var enemy: Enemy = result.spawned_enemies[0]

	assert_eq(result.spawned_enemies.size(), 1)
	assert_eq(enemy.id, "wave-1-enemy-1")
	assert_eq(enemy.max_health, 24.0)
	assert_eq(enemy.health, 24.0)
	assert_eq(enemy.speed_cells_per_second, 1.25)
	assert_eq(enemy.kill_reward, 6)
	assert_eq(enemy.armor_type, DamageTypes.ArmorType.LIGHT)
	assert_eq(enemy.race_type, DamageTypes.RaceType.UNDEAD)
	assert_eq(enemy.school_resistance_overrides[DamageTypes.DamageSchool.FIRE], -0.25)


func test_large_delta_spawns_multiple_enemies_without_exceeding_wave_count() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 3, 0.5, 20.0, 1.0, 5, 20),
	])

	var result := spawner.advance(2.0, [])

	assert_eq(result.spawned_enemies.size(), 3)
	assert_eq(result.spawned_enemies[0].id, "wave-1-enemy-1")
	assert_eq(result.spawned_enemies[1].id, "wave-1-enemy-2")
	assert_eq(result.spawned_enemies[2].id, "wave-1-enemy-3")
	assert_eq(spawner.current_wave_state.spawned_count, 3)


func test_wave_clears_after_all_spawned_enemies_are_finished() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 2, 0.5, 20.0, 1.0, 5, 20),
	])
	var enemies := []
	enemies.append_array(spawner.advance(1.0, enemies).spawned_enemies)
	for enemy in enemies:
		enemy.defeated = true

	var result := spawner.advance(0.1, enemies)
	var second_result := spawner.advance(0.1, enemies)

	assert_eq(result.wave_clear_events.size(), 1)
	assert_eq(result.wave_clear_events[0].wave_id, "wave-1")
	assert_eq(result.wave_clear_events[0].reward_gold, 20)
	assert_true(result.all_waves_cleared)
	assert_eq(second_result.wave_clear_events.size(), 0)


func test_next_wave_starts_on_tick_after_previous_wave_clears() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 1, 0.5, 20.0, 1.0, 5, 20),
		WaveDefinition.new("wave-2", 1, 0.5, 30.0, 1.1, 6, 25),
	])
	var enemies := []
	enemies.append_array(spawner.advance(0.5, enemies).spawned_enemies)
	enemies[0].completed = true

	var clear_result := spawner.advance(0.1, enemies)
	var spawn_result := spawner.advance(0.5, enemies)

	assert_eq(clear_result.wave_clear_events.size(), 1)
	assert_eq(clear_result.current_wave_index, 1)
	assert_false(clear_result.all_waves_cleared)
	assert_eq(spawn_result.spawned_enemies.size(), 1)
	assert_eq(spawn_result.spawned_enemies[0].id, "wave-2-enemy-1")
	assert_eq(spawn_result.spawned_enemies[0].max_health, 30.0)


func test_all_waves_cleared_after_final_wave_finishes() -> void:
	var spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 1, 0.5, 20.0, 1.0, 5, 20),
	])
	var enemies := spawner.advance(0.5, []).spawned_enemies
	enemies[0].completed = true

	var result := spawner.advance(0.1, enemies)

	assert_true(result.all_waves_cleared)
	assert_true(spawner.all_waves_cleared)
