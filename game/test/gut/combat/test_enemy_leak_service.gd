extends GutTest


func test_collect_leak_events_emits_for_completed_enemy() -> void:
	var service := EnemyLeakService.new()
	var enemy := Enemy.new("enemy-1", 1.0)
	enemy.completed = true

	var leak_events := service.collect_leak_events([enemy])

	assert_eq(leak_events.size(), 1)
	assert_eq(leak_events[0].enemy_id, "enemy-1")
	assert_eq(leak_events[0].life_damage, 1)


func test_collect_leak_events_ignores_active_and_defeated_enemies() -> void:
	var service := EnemyLeakService.new()
	var active_enemy := Enemy.new("enemy-active", 1.0)
	var defeated_enemy := Enemy.new("enemy-defeated", 1.0)
	defeated_enemy.defeated = true

	var leak_events := service.collect_leak_events([active_enemy, defeated_enemy])

	assert_eq(leak_events.size(), 0)


func test_collect_leak_events_does_not_duplicate_same_enemy() -> void:
	var service := EnemyLeakService.new()
	var enemy := Enemy.new("enemy-1", 1.0)
	enemy.completed = true

	var first_events := service.collect_leak_events([enemy])
	var second_events := service.collect_leak_events([enemy])

	assert_eq(first_events.size(), 1)
	assert_eq(second_events.size(), 0)
