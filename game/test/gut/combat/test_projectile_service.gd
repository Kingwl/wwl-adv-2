extends GutTest


func test_projectile_moves_without_damage_before_hit() -> void:
	var service := ProjectileService.new()
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	enemy.path_distance = 1.0
	var projectile := CombatProjectile.new(
		"projectile-1",
		"tower-a",
		"enemy-1",
		GameTower.Type.SINGLE_TARGET,
		Vector2(0.5, 1.5),
		1.0,
		0.05,
		10.0
	)

	var result := service.advance([projectile], [enemy], follower, 0.1)

	assert_eq(result.active_projectiles.size(), 1)
	assert_eq(result.damage_events.size(), 0)
	assert_eq(result.impact_events.size(), 0)
	assert_false(projectile.position == Vector2(0.5, 1.5))
	assert_true(projectile.active)


func test_projectile_hits_target_and_emits_damage() -> void:
	var service := ProjectileService.new()
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var projectile := CombatProjectile.new(
		"projectile-1",
		"tower-a",
		"enemy-1",
		GameTower.Type.SINGLE_TARGET,
		Vector2(0.5, 0.75),
		10.0,
		0.05,
		10.0
	)

	var result := service.advance([projectile], [enemy], follower, 0.1)

	assert_eq(result.active_projectiles.size(), 0)
	assert_false(projectile.active)
	assert_eq(result.damage_events.size(), 1)
	assert_eq(result.damage_events[0].enemy_id, "enemy-1")
	assert_eq(result.damage_events[0].amount, 10.0)
	assert_eq(result.impact_events.size(), 1)
	assert_true(result.impact_events[0].hit)
	assert_eq(result.impact_events[0].tower_type, GameTower.Type.SINGLE_TARGET)


func test_area_projectile_damages_enemies_inside_splash_only() -> void:
	var service := ProjectileService.new()
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	var target_enemy := Enemy.new("enemy-target", 1.0, 20.0, 5)
	var nearby_enemy := Enemy.new("enemy-nearby", 1.0, 20.0, 5)
	var far_enemy := Enemy.new("enemy-far", 1.0, 20.0, 5)
	target_enemy.path_distance = 1.5
	nearby_enemy.path_distance = 1.0
	far_enemy.path_distance = 0.0
	var projectile := CombatProjectile.new(
		"projectile-1",
		"tower-a",
		"enemy-target",
		GameTower.Type.AREA,
		Vector2(2.0, 0.5),
		10.0,
		0.05,
		6.0,
		0.75
	)

	var result := service.advance([projectile], [far_enemy, nearby_enemy, target_enemy], follower, 0.1)

	assert_eq(result.damage_events.size(), 2)
	assert_true(_has_damage_event_for(result, "enemy-target"))
	assert_true(_has_damage_event_for(result, "enemy-nearby"))
	assert_false(_has_damage_event_for(result, "enemy-far"))


func test_slow_projectile_emits_slow_status_on_hit() -> void:
	var service := ProjectileService.new()
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	var projectile := CombatProjectile.new(
		"projectile-1",
		"tower-a",
		"enemy-1",
		GameTower.Type.SLOW,
		Vector2(0.5, 0.75),
		10.0,
		0.05,
		3.0,
		0.0,
		0.6,
		1.5
	)

	var result := service.advance([projectile], [enemy], follower, 0.1)

	assert_eq(result.damage_events.size(), 1)
	assert_eq(result.status_events.size(), 1)
	assert_eq(result.status_events[0].enemy_id, "enemy-1")
	assert_eq(result.status_events[0].status_type, StatusEvent.StatusType.SLOW)
	assert_eq(result.status_events[0].duration, 1.5)
	assert_eq(result.status_events[0].multiplier, 0.6)


func test_projectile_misses_when_target_is_no_longer_active() -> void:
	var service := ProjectileService.new()
	var follower := PathFollower.new([Vector2i(0, 0), Vector2i(1, 0)])
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	enemy.completed = true
	var projectile := CombatProjectile.new(
		"projectile-1",
		"tower-a",
		"enemy-1",
		GameTower.Type.SINGLE_TARGET,
		Vector2(0.5, 0.5),
		10.0,
		0.05,
		10.0
	)

	var result := service.advance([projectile], [enemy], follower, 0.1)

	assert_eq(result.active_projectiles.size(), 0)
	assert_eq(result.damage_events.size(), 0)
	assert_eq(result.impact_events.size(), 0)
	assert_eq(result.missed_projectile_ids, ["projectile-1"])


func _has_damage_event_for(result: ProjectileAdvanceResult, enemy_id: String) -> bool:
	for damage_event in result.damage_events:
		if damage_event.enemy_id == enemy_id:
			return true

	return false
