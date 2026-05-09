class_name Board
extends RefCounted

var width: int
var height: int

var _slots: Dictionary


func _init(new_width: int, new_height: int, default_slot_type: BoardSlot.Type = BoardSlot.Type.BUILDABLE) -> void:
	assert(new_width > 0, "Board width must be positive.")
	assert(new_height > 0, "Board height must be positive.")

	width = new_width
	height = new_height
	_slots = {}

	for y in range(height):
		for x in range(width):
			var position := Vector2i(x, y)
			_slots[position] = BoardSlot.new(position, default_slot_type)


func is_in_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < width and position.y < height


func get_slot(position: Vector2i) -> BoardSlot:
	assert(is_in_bounds(position), "Slot position is out of bounds.")
	return _slots[position]


func get_slot_type(position: Vector2i) -> BoardSlot.Type:
	return get_slot(position).slot_type


func set_slot_type(position: Vector2i, slot_type: BoardSlot.Type) -> void:
	get_slot(position).slot_type = slot_type


func get_occupant_id(position: Vector2i) -> String:
	return get_slot(position).occupant_id


func set_reserved(position: Vector2i, reserved: bool) -> void:
	get_slot(position).reserved = reserved


func can_place_tower(position: Vector2i, tower_id: String = "") -> PlacementResult:
	if not is_in_bounds(position):
		return PlacementResult.failure(
			PlacementResult.FailureReason.OUT_OF_BOUNDS,
			"Cannot place tower outside the board.",
			position
		)

	var slot := get_slot(position)

	if not slot.is_buildable():
		return PlacementResult.failure(
			PlacementResult.FailureReason.NOT_BUILDABLE,
			"Tower can only be placed on buildable slots.",
			position
		)

	if not slot.is_empty():
		return PlacementResult.failure(
			PlacementResult.FailureReason.OCCUPIED,
			"Slot is already occupied.",
			position,
			slot.occupant_id
		)

	if slot.reserved:
		return PlacementResult.failure(
			PlacementResult.FailureReason.RESERVED,
			"Slot is reserved.",
			position
		)

	return PlacementResult.success(position, tower_id)


func place_tower(position: Vector2i, tower_id: String) -> PlacementResult:
	assert(not tower_id.is_empty(), "Tower id is required.")

	var placement_check := can_place_tower(position, tower_id)
	if not placement_check.succeeded:
		return placement_check

	var slot := get_slot(position)
	slot.occupant_id = tower_id
	return PlacementResult.success(position, tower_id)


func remove_tower(position: Vector2i, expected_occupant_id: String = "") -> RemovalResult:
	if not is_in_bounds(position):
		return RemovalResult.failure(
			RemovalResult.FailureReason.OUT_OF_BOUNDS,
			"Cannot remove tower outside the board.",
			position
		)

	var slot := get_slot(position)

	if slot.is_empty():
		return RemovalResult.failure(
			RemovalResult.FailureReason.EMPTY,
			"Slot does not contain a tower.",
			position
		)

	if not expected_occupant_id.is_empty() and expected_occupant_id != slot.occupant_id:
		return RemovalResult.failure(
			RemovalResult.FailureReason.OCCUPANT_MISMATCH,
			"Slot contains a different tower.",
			position,
			slot.occupant_id
		)

	var removed_occupant_id := slot.occupant_id
	slot.occupant_id = ""
	return RemovalResult.success(position, removed_occupant_id)


func set_path(path: Array) -> void:
	for position in path:
		set_slot_type(position, BoardSlot.Type.PATH)


func validate_path(path: Array) -> PathValidationResult:
	if path.size() < 2:
		return PathValidationResult.failure(
			PathValidationResult.FailureReason.TOO_SHORT,
			"Path must contain at least two slots."
		)

	for position in path:
		if not is_in_bounds(position):
			return PathValidationResult.failure(
				PathValidationResult.FailureReason.OUT_OF_BOUNDS,
				"Path contains a slot outside the board.",
				position
			)

	for position in path:
		if get_slot_type(position) != BoardSlot.Type.PATH:
			return PathValidationResult.failure(
				PathValidationResult.FailureReason.NOT_PATH_SLOT,
				"Path contains a slot that is not marked as PATH.",
				position
			)

	for index in range(1, path.size()):
		var previous: Vector2i = path[index - 1]
		var current: Vector2i = path[index]
		var distance: int = abs(current.x - previous.x) + abs(current.y - previous.y)

		if distance != 1:
			return PathValidationResult.failure(
				PathValidationResult.FailureReason.NOT_CONTIGUOUS,
				"Path steps must be orthogonally adjacent.",
				current
			)

	return PathValidationResult.success()
