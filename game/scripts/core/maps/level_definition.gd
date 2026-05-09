class_name LevelDefinition
extends RefCounted

var id: String
var display_name: String
var style_id: String
var grid_width: int
var grid_height: int
var path_cells: Array
var blocked_cells: Array
var locked_cells: Array
var spawn_cell: Vector2i
var exit_cell: Vector2i


static func load_from_path(resource_path: String) -> LevelDefinition:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load level definition: %s" % resource_path)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Level definition must be a JSON object: %s" % resource_path)
		return null

	return LevelDefinition.from_dictionary(parsed as Dictionary)


static func from_dictionary(data: Dictionary) -> LevelDefinition:
	var level := LevelDefinition.new()
	var grid: Dictionary = data.get("grid", {}) as Dictionary

	level.id = data.get("id", "")
	level.display_name = data.get("display_name", level.id)
	level.style_id = data.get("style_id", "")
	level.grid_width = int(grid.get("width", 0))
	level.grid_height = int(grid.get("height", 0))
	level.path_cells = LevelDefinition._cells_to_vector2i(data.get("path_cells", []))
	level.blocked_cells = LevelDefinition._cells_to_vector2i(data.get("blocked_cells", []))
	level.locked_cells = LevelDefinition._cells_to_vector2i(data.get("locked_cells", []))
	level.spawn_cell = LevelDefinition._cell_to_vector2i(data.get("spawn_cell", [0, 0]))
	level.exit_cell = LevelDefinition._cell_to_vector2i(data.get("exit_cell", [0, 0]))

	return level


func apply_to_board(board: Board) -> void:
	assert(board != null, "Board is required.")

	for position in blocked_cells:
		board.set_slot_type(position, BoardSlot.Type.BLOCKED)

	for position in locked_cells:
		board.set_slot_type(position, BoardSlot.Type.LOCKED)

	board.set_path(path_cells)


func is_valid() -> bool:
	return grid_width > 0 and grid_height > 0 and path_cells.size() >= 2 and not style_id.is_empty()


static func _cells_to_vector2i(cells: Array) -> Array:
	var result := []
	for cell in cells:
		result.append(LevelDefinition._cell_to_vector2i(cell))

	return result


static func _cell_to_vector2i(cell) -> Vector2i:
	if cell is Vector2i:
		return cell

	if cell is Array and cell.size() >= 2:
		return Vector2i(int(cell[0]), int(cell[1]))

	return Vector2i.ZERO
