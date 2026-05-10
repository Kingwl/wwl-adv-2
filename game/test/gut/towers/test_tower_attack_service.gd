extends GutTest


func test_cooldown_prevents_attack_and_ticks_down() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()
	tower.cooldown_remaining = 0.5

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, AttackResult.FailureReason.COOLDOWN)
	assert_eq(tower.cooldown_remaining, 0.4)
	assert_eq(result.damage_events.size(), 0)


func test_no_target_does_not_reset_cooldown() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(5, 5), Vector2i(6, 5)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, AttackResult.FailureReason.NO_TARGET)
	assert_eq(tower.cooldown_remaining, 0.0)
	assert_eq(result.damage_events.size(), 0)


func test_single_target_tower_emits_one_damage_event() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_eq(result.target_enemy_id, "enemy-1")
	assert_eq(result.damage_events.size(), 0)
	assert_eq(result.status_events.size(), 0)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.target_enemy_id, "enemy-1")
	assert_eq(result.projectile.damage, 10.0)
	assert_eq(result.projectile.attack_type, DamageTypes.AttackType.PIERCE)
	assert_eq(result.projectile.damage_school, DamageTypes.DamageSchool.PHYSICAL)
	assert_eq(result.projectile.tower_id, "tower-a")
	assert_eq(result.projectile.tower_type, GameTower.Type.SINGLE_TARGET)
	assert_eq(tower.cooldown_remaining, 1.0)


func test_upgraded_single_target_uses_tier_stats_for_projectile_and_cooldown() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 2, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.damage, 18.0)
	assert_eq(result.projectile.splash_radius_cells, 0.0)
	assert_eq(tower.cooldown_remaining, 0.9)


func test_area_tower_damages_enemies_near_target() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.AREA, 1, Vector2i(1, 0))
	var target_enemy := Enemy.new("enemy-target", 1.0)
	var nearby_enemy := Enemy.new("enemy-nearby", 1.0)
	var far_enemy := Enemy.new("enemy-far", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	var service := TowerAttackService.new()
	target_enemy.path_distance = 1.5
	nearby_enemy.path_distance = 1.0
	far_enemy.path_distance = 0.0

	var result := service.tick_tower(tower, 0.1, [far_enemy, nearby_enemy, target_enemy], follower)

	assert_true(result.succeeded)
	assert_eq(result.target_enemy_id, "enemy-target")
	assert_eq(result.damage_events.size(), 0)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.target_enemy_id, "enemy-target")
	assert_eq(result.projectile.damage, 6.0)
	assert_eq(result.projectile.attack_type, DamageTypes.AttackType.SIEGE)
	assert_eq(result.projectile.damage_school, DamageTypes.DamageSchool.PHYSICAL)
	assert_eq(result.projectile.splash_radius_cells, 0.75)
	assert_eq(result.projectile.tower_type, GameTower.Type.AREA)
	assert_eq(tower.cooldown_remaining, 1.4)


func test_upgraded_area_tower_uses_tier_stats_for_splash_projectile() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.AREA, 3, Vector2i(1, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var service := TowerAttackService.new()
	enemy.path_distance = 1.5

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.damage, 16.0)
	assert_eq(result.projectile.splash_radius_cells, 1.15)
	assert_eq(tower.cooldown_remaining, 1.2)


func test_slow_tower_emits_damage_and_slow_status_events() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SLOW, 1, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_eq(result.damage_events.size(), 0)
	assert_eq(result.status_events.size(), 0)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.damage, 3.0)
	assert_eq(result.projectile.attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(result.projectile.damage_school, DamageTypes.DamageSchool.FROST)
	assert_eq(result.projectile.slow_duration, 1.5)
	assert_eq(result.projectile.slow_multiplier, 0.6)
	assert_eq(result.projectile.tower_type, GameTower.Type.SLOW)
	assert_eq(tower.cooldown_remaining, 1.2)


func test_upgraded_slow_tower_uses_tier_stats_for_status_projectile() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SLOW, 3, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.damage, 8.0)
	assert_eq(result.projectile.slow_duration, 2.5)
	assert_eq(result.projectile.slow_multiplier, 0.5)
	assert_eq(tower.cooldown_remaining, 1.1)


func test_flame_tower_emits_fire_projectile_with_burn_status() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.FLAME, 1, Vector2i(0, 0))
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var service := TowerAttackService.new()

	var result := service.tick_tower(tower, 0.1, [enemy], follower)

	assert_true(result.succeeded)
	assert_not_null(result.projectile)
	assert_eq(result.projectile.damage, 4.0)
	assert_eq(result.projectile.attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(result.projectile.damage_school, DamageTypes.DamageSchool.FIRE)
	assert_eq(result.projectile.tower_type, GameTower.Type.FLAME)
	assert_eq(result.projectile.status_type, StatusEvent.StatusType.BURN)
	assert_eq(result.projectile.status_duration, 3.0)
	assert_eq(result.projectile.status_tick_interval, 1.0)
	assert_eq(result.projectile.status_tick_damage, 2.0)
	assert_eq(tower.cooldown_remaining, 1.25)
