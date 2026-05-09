extends GutTest


func test_board_creates_requested_size_with_buildable_slots() -> void:
	var board := Board.new(3, 2)

	assert_eq(board.width, 3)
	assert_eq(board.height, 2)
	assert_true(board.is_in_bounds(Vector2i(2, 1)))
	assert_false(board.is_in_bounds(Vector2i(3, 1)))
	assert_eq(board.get_slot_type(Vector2i(0, 0)), BoardSlot.Type.BUILDABLE)


func test_place_tower_on_empty_buildable_slot_succeeds() -> void:
	var board := Board.new(3, 2)

	var result := board.place_tower(Vector2i(1, 1), "tower-a")

	assert_true(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.NONE)
	assert_eq(result.position, Vector2i(1, 1))
	assert_eq(result.occupant_id, "tower-a")
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "tower-a")


func test_place_tower_out_of_bounds_returns_structured_failure() -> void:
	var board := Board.new(3, 2)

	var result := board.place_tower(Vector2i(3, 0), "tower-a")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.OUT_OF_BOUNDS)
	assert_eq(result.position, Vector2i(3, 0))
	assert_eq(result.occupant_id, "")


func test_place_tower_on_path_slot_returns_not_buildable() -> void:
	var board := Board.new(3, 2)
	board.set_slot_type(Vector2i(1, 0), BoardSlot.Type.PATH)

	var result := board.place_tower(Vector2i(1, 0), "tower-a")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.NOT_BUILDABLE)
	assert_eq(board.get_occupant_id(Vector2i(1, 0)), "")


func test_place_tower_on_blocked_slot_returns_not_buildable() -> void:
	var board := Board.new(3, 2)
	board.set_slot_type(Vector2i(1, 0), BoardSlot.Type.BLOCKED)

	var result := board.place_tower(Vector2i(1, 0), "tower-a")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.NOT_BUILDABLE)


func test_place_tower_on_locked_slot_returns_not_buildable() -> void:
	var board := Board.new(3, 2)
	board.set_slot_type(Vector2i(1, 0), BoardSlot.Type.LOCKED)

	var result := board.place_tower(Vector2i(1, 0), "tower-a")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.NOT_BUILDABLE)


func test_place_tower_on_occupied_slot_returns_occupied() -> void:
	var board := Board.new(3, 2)
	board.place_tower(Vector2i(1, 1), "tower-a")

	var result := board.place_tower(Vector2i(1, 1), "tower-b")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.OCCUPIED)
	assert_eq(result.occupant_id, "tower-a")
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "tower-a")


func test_place_tower_on_reserved_slot_returns_reserved() -> void:
	var board := Board.new(3, 2)
	board.set_reserved(Vector2i(1, 1), true)

	var result := board.place_tower(Vector2i(1, 1), "tower-a")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, PlacementResult.FailureReason.RESERVED)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "")


func test_remove_tower_clears_occupied_slot() -> void:
	var board := Board.new(3, 2)
	board.place_tower(Vector2i(1, 1), "tower-a")

	var result := board.remove_tower(Vector2i(1, 1), "tower-a")

	assert_true(result.succeeded)
	assert_eq(result.failure_reason, RemovalResult.FailureReason.NONE)
	assert_eq(result.position, Vector2i(1, 1))
	assert_eq(result.removed_occupant_id, "tower-a")
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "")


func test_remove_tower_from_empty_slot_returns_failure() -> void:
	var board := Board.new(3, 2)

	var result := board.remove_tower(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, RemovalResult.FailureReason.EMPTY)
	assert_eq(result.removed_occupant_id, "")


func test_remove_tower_with_wrong_id_returns_occupant_mismatch() -> void:
	var board := Board.new(3, 2)
	board.place_tower(Vector2i(1, 1), "tower-a")

	var result := board.remove_tower(Vector2i(1, 1), "tower-b")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, RemovalResult.FailureReason.OCCUPANT_MISMATCH)
	assert_eq(result.removed_occupant_id, "tower-a")
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "tower-a")
