extends GutTest


func test_advance_accumulates_delta_until_fixed_step() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var simulation := CombatSimulation.new([], [enemy], follower, 0.1)

	var tick_results := simulation.advance(0.05)

	assert_eq(tick_results.size(), 0)
	assert_almost_eq(simulation.accumulator_seconds, 0.05, 0.00001)
	assert_eq(enemy.path_distance, 0.0)


func test_advance_runs_fixed_steps_and_keeps_remainder() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var simulation := CombatSimulation.new([], [enemy], follower, 0.1)

	var tick_results := simulation.advance(0.25)

	assert_eq(tick_results.size(), 2)
	assert_almost_eq(simulation.accumulator_seconds, 0.05, 0.00001)
	assert_almost_eq(enemy.path_distance, 0.2, 0.00001)
	assert_eq(tick_results[0].delta_seconds, 0.1)
	assert_eq(tick_results[1].delta_seconds, 0.1)


func test_tick_moves_enemy_attacks_and_applies_damage() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 1))
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var simulation := CombatSimulation.new([tower], [enemy], follower, 0.1)

	var result := simulation.tick(0.1)
	assert_almost_eq(enemy.path_distance, 0.1, 0.00001)
	assert_eq(result.spawned_projectiles.size(), 1)
	assert_eq(result.damage_events.size(), 0)
	assert_eq(result.attack_results.size(), 1)
	assert_true(result.attack_results[0].succeeded)

	var hit_result := simulation.tick(0.1)

	assert_eq(enemy.health, 10.0)
	assert_eq(hit_result.damage_events.size(), 1)
	assert_eq(hit_result.damage_result.applied_damage_events.size(), 1)
	assert_eq(hit_result.damage_result.death_events.size(), 0)
	assert_eq(hit_result.projectile_impact_events.size(), 1)


func test_tick_emits_death_event_when_damage_is_lethal() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 1))
	var enemy := Enemy.new("enemy-1", 1.0, 10.0, 5)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var simulation := CombatSimulation.new([tower], [enemy], follower, 0.1)

	simulation.tick(0.1)
	var result := simulation.tick(0.1)

	assert_true(enemy.defeated)
	assert_eq(enemy.health, 0.0)
	assert_eq(result.damage_result.death_events.size(), 1)
	assert_eq(result.damage_result.death_events[0].enemy_id, "enemy-1")
	assert_eq(result.damage_result.death_events[0].reward_gold, 5)


func test_advance_does_not_tick_towers_before_fixed_step_is_available() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 1))
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var simulation := CombatSimulation.new([tower], [enemy], follower, 0.1)

	var first_results := simulation.advance(0.05)
	var second_results := simulation.advance(0.05)

	assert_eq(first_results.size(), 0)
	assert_eq(second_results.size(), 1)
	assert_eq(enemy.health, 20.0)
	assert_eq(simulation.projectiles.size(), 1)
	assert_eq(tower.cooldown_remaining, 1.0)


func test_tick_spawns_wave_enemies_before_movement() -> void:
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var wave_spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 1, 0.1, 20.0, 1.0, 5, 20),
	])
	var simulation := CombatSimulation.new([], [], follower, 0.1, null, null, wave_spawner)

	var result := simulation.tick(0.1)
	var enemy: Enemy = simulation.enemies[0]

	assert_eq(result.spawned_enemies.size(), 1)
	assert_eq(result.spawned_enemies[0].id, "wave-1-enemy-1")
	assert_eq(simulation.enemies.size(), 1)
	assert_almost_eq(enemy.path_distance, 0.1, 0.00001)


func test_tick_reports_wave_clear_events_from_wave_spawner() -> void:
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var wave_spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 1, 0.1, 20.0, 1.0, 5, 20),
	])
	var simulation := CombatSimulation.new([], [], follower, 0.1, null, null, wave_spawner)

	simulation.tick(0.1)
	var enemy: Enemy = simulation.enemies[0]
	enemy.defeated = true
	var result := simulation.tick(0.1)

	assert_eq(result.wave_clear_events.size(), 1)
	assert_eq(result.wave_clear_events[0].wave_id, "wave-1")
	assert_eq(result.wave_clear_events[0].reward_gold, 20)
	assert_true(result.all_waves_cleared)


func test_tick_reduces_lives_when_enemy_reaches_path_end() -> void:
	var enemy := Enemy.new("enemy-1", 20.0, 20.0, 5)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var player_life := PlayerLife.new(3)
	var simulation := CombatSimulation.new([], [enemy], follower, 0.1, null, null, null, null, player_life)

	var result := simulation.tick(0.1)
	var second_result := simulation.tick(0.1)

	assert_true(enemy.completed)
	assert_eq(result.enemy_leak_events.size(), 1)
	assert_eq(result.enemy_leak_events[0].enemy_id, "enemy-1")
	assert_eq(result.lives_remaining, 2)
	assert_false(result.game_failed)
	assert_eq(second_result.enemy_leak_events.size(), 0)
	assert_eq(second_result.lives_remaining, 2)


func test_tick_marks_game_failed_when_lives_reach_zero() -> void:
	var enemy := Enemy.new("enemy-1", 20.0, 20.0, 5)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var player_life := PlayerLife.new(1)
	var simulation := CombatSimulation.new([], [enemy], follower, 0.1, null, null, null, null, player_life)

	var result := simulation.tick(0.1)

	assert_true(result.game_failed)
	assert_false(result.game_won)
	assert_true(simulation.game_failed)
	assert_eq(player_life.lives, 0)


func test_tick_marks_game_won_when_all_waves_clear_with_lives_remaining() -> void:
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var wave_spawner := WaveSpawner.new([
		WaveDefinition.new("wave-1", 1, 0.1, 20.0, 1.0, 5, 20),
	])
	var player_life := PlayerLife.new(3)
	var simulation := CombatSimulation.new([], [], follower, 0.1, null, null, wave_spawner, null, player_life)

	simulation.tick(0.1)
	var enemy: Enemy = simulation.enemies[0]
	enemy.defeated = true
	var result := simulation.tick(0.1)

	assert_true(result.game_won)
	assert_false(result.game_failed)
	assert_true(simulation.game_won)
	assert_eq(result.lives_remaining, 3)
