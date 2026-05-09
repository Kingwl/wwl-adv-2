extends GutTest


func test_enemy_starts_at_path_start_center() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)])

	assert_eq(follower.get_grid_space_position(enemy), Vector2(0.5, 3.5))
	assert_eq(follower.get_grid_position(enemy), Vector2i(0, 3))
	assert_false(enemy.completed)


func test_advance_moves_enemy_along_first_segment() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)])

	follower.advance(enemy, 0.5)

	assert_eq(follower.get_grid_space_position(enemy), Vector2(1.0, 3.5))
	assert_eq(enemy.path_distance, 0.5)
	assert_false(enemy.completed)


func test_advance_can_cross_multiple_segments() -> void:
	var enemy := Enemy.new("enemy-1", 2.0)
	var follower := PathFollower.new([
		Vector2i(0, 3),
		Vector2i(1, 3),
		Vector2i(1, 4),
		Vector2i(2, 4),
	])

	follower.advance(enemy, 1.25)

	assert_eq(enemy.path_distance, 2.5)
	assert_eq(follower.get_grid_space_position(enemy), Vector2(2.0, 4.5))
	assert_eq(follower.get_grid_position(enemy), Vector2i(1, 4))
	assert_false(enemy.completed)


func test_advance_marks_enemy_completed_at_end() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)])

	follower.advance(enemy, 3.0)

	assert_true(enemy.completed)
	assert_eq(enemy.path_distance, follower.total_distance)
	assert_eq(follower.get_grid_space_position(enemy), Vector2(2.5, 3.5))
	assert_eq(follower.get_grid_position(enemy), Vector2i(2, 3))


func test_completed_enemy_does_not_move_after_more_ticks() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3)])

	follower.advance(enemy, 2.0)
	var completed_position := follower.get_grid_space_position(enemy)
	follower.advance(enemy, 5.0)

	assert_true(enemy.completed)
	assert_eq(follower.get_grid_space_position(enemy), completed_position)
	assert_eq(enemy.path_distance, follower.total_distance)


func test_defeated_enemy_does_not_move() -> void:
	var enemy := Enemy.new("enemy-1", 1.0)
	var follower := PathFollower.new([Vector2i(0, 3), Vector2i(1, 3)])
	enemy.apply_damage(enemy.health)

	follower.advance(enemy, 1.0)

	assert_true(enemy.defeated)
	assert_eq(enemy.path_distance, 0.0)
	assert_eq(follower.get_grid_space_position(enemy), Vector2(0.5, 3.5))


func test_same_inputs_produce_same_result() -> void:
	var path := [Vector2i(0, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(2, 4)]
	var first_enemy := Enemy.new("enemy-1", 1.5)
	var second_enemy := Enemy.new("enemy-2", 1.5)
	var follower := PathFollower.new(path)

	follower.advance(first_enemy, 0.25)
	follower.advance(first_enemy, 0.25)
	follower.advance(second_enemy, 0.5)

	assert_eq(first_enemy.path_distance, second_enemy.path_distance)
	assert_eq(follower.get_grid_space_position(first_enemy), follower.get_grid_space_position(second_enemy))
	assert_eq(first_enemy.completed, second_enemy.completed)
