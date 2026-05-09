extends GutTest


func test_player_life_starts_with_default_lives() -> void:
	var player_life := PlayerLife.new()

	assert_eq(player_life.max_lives, 10)
	assert_eq(player_life.lives, 10)
	assert_false(player_life.failed)


func test_apply_leak_events_reduces_lives() -> void:
	var player_life := PlayerLife.new(10)

	var lost_lives := player_life.apply_leak_events([
		EnemyLeakEvent.new("enemy-1", 1),
		EnemyLeakEvent.new("enemy-2", 2),
	])

	assert_eq(lost_lives, 3)
	assert_eq(player_life.lives, 7)
	assert_false(player_life.failed)


func test_apply_leak_events_clamps_lives_and_marks_failed() -> void:
	var player_life := PlayerLife.new(2)

	var lost_lives := player_life.apply_leak_events([
		EnemyLeakEvent.new("enemy-1", 3),
	])

	assert_eq(lost_lives, 3)
	assert_eq(player_life.lives, 0)
	assert_true(player_life.failed)


func test_apply_leak_events_ignores_non_leak_events() -> void:
	var player_life := PlayerLife.new(2)

	var lost_lives := player_life.apply_leak_events([
		null,
		EnemyDeathEvent.new("enemy-1", 5, "tower-a"),
	])

	assert_eq(lost_lives, 0)
	assert_eq(player_life.lives, 2)
	assert_false(player_life.failed)
