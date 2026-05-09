extends GutTest


func test_first_targeting_returns_null_when_no_enemy_is_in_range() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 0))
	var stats := TowerStats.new(10.0, 1.0, 1.0)
	var follower := PathFollower.new([Vector2i(5, 5), Vector2i(6, 5)])
	var enemy := Enemy.new("enemy-1", 1.0)
	var service := TargetingService.new()

	var target := service.select_target(tower, stats, [enemy], follower)

	assert_null(target)


func test_first_targeting_selects_enemy_with_largest_path_distance() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(1, 3))
	var stats := TowerStats.new(10.0, 3.0, 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)])
	var early_enemy := Enemy.new("enemy-early", 1.0)
	var later_enemy := Enemy.new("enemy-later", 1.0)
	var service := TargetingService.new()
	early_enemy.path_distance = 0.5
	later_enemy.path_distance = 2.0

	var target := service.select_target(tower, stats, [early_enemy, later_enemy], follower)

	assert_eq(target, later_enemy)


func test_first_targeting_ignores_completed_enemies() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(1, 3))
	var stats := TowerStats.new(10.0, 3.0, 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)])
	var active_enemy := Enemy.new("enemy-active", 1.0)
	var completed_enemy := Enemy.new("enemy-completed", 1.0)
	var service := TargetingService.new()
	active_enemy.path_distance = 1.0
	completed_enemy.path_distance = 2.0
	completed_enemy.completed = true

	var target := service.select_target(tower, stats, [active_enemy, completed_enemy], follower)

	assert_eq(target, active_enemy)


func test_first_targeting_ignores_defeated_enemies() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(1, 3))
	var stats := TowerStats.new(10.0, 3.0, 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)])
	var active_enemy := Enemy.new("enemy-active", 1.0)
	var defeated_enemy := Enemy.new("enemy-defeated", 1.0)
	var service := TargetingService.new()
	active_enemy.path_distance = 1.0
	defeated_enemy.path_distance = 2.0
	defeated_enemy.apply_damage(defeated_enemy.health)

	var target := service.select_target(tower, stats, [active_enemy, defeated_enemy], follower)

	assert_eq(target, active_enemy)


func test_first_targeting_ignores_enemies_outside_range() -> void:
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(0, 0))
	var stats := TowerStats.new(10.0, 1.0, 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)])
	var near_enemy := Enemy.new("enemy-near", 1.0)
	var far_enemy := Enemy.new("enemy-far", 1.0)
	var service := TargetingService.new()
	near_enemy.path_distance = 0.0
	far_enemy.path_distance = 2.0

	var target := service.select_target(tower, stats, [near_enemy, far_enemy], follower)

	assert_null(target)
