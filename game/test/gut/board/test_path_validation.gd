extends GutTest


func test_valid_path_requires_path_slots_and_orthogonal_steps() -> void:
	var board := Board.new(4, 3)
	var path := [
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(2, 2),
	]
	board.set_path(path)

	var result := board.validate_path(path)

	assert_true(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.NONE)
	assert_eq(result.position, Vector2i(-1, -1))


func test_path_with_less_than_two_slots_fails() -> void:
	var board := Board.new(4, 3)

	var result := board.validate_path([Vector2i(0, 1)])

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.TOO_SHORT)


func test_path_with_out_of_bounds_slot_fails() -> void:
	var board := Board.new(4, 3)
	var path := [Vector2i(0, 1), Vector2i(4, 1)]

	var result := board.validate_path(path)

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.OUT_OF_BOUNDS)
	assert_eq(result.position, Vector2i(4, 1))


func test_path_with_non_path_slot_fails() -> void:
	var board := Board.new(4, 3)
	board.set_slot_type(Vector2i(0, 1), BoardSlot.Type.PATH)

	var result := board.validate_path([Vector2i(0, 1), Vector2i(1, 1)])

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.NOT_PATH_SLOT)
	assert_eq(result.position, Vector2i(1, 1))


func test_path_with_diagonal_step_fails() -> void:
	var board := Board.new(4, 3)
	var path := [Vector2i(0, 0), Vector2i(1, 1)]
	board.set_path(path)

	var result := board.validate_path(path)

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.NOT_CONTIGUOUS)
	assert_eq(result.position, Vector2i(1, 1))


func test_path_with_jump_step_fails() -> void:
	var board := Board.new(4, 3)
	var path := [Vector2i(0, 1), Vector2i(2, 1)]
	board.set_path(path)

	var result := board.validate_path(path)

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PathValidationResult.FailureReason.NOT_CONTIGUOUS)
	assert_eq(result.position, Vector2i(2, 1))
