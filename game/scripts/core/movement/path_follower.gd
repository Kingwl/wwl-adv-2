class_name PathFollower
extends RefCounted

var path: Array
var total_distance: float


func _init(new_path: Array) -> void:
	assert(new_path.size() >= 2, "Path must contain at least two points.")

	path = new_path.duplicate()
	total_distance = float(path.size() - 1)

	for index in range(1, path.size()):
		var previous: Vector2i = path[index - 1]
		var current: Vector2i = path[index]
		var distance: int = abs(current.x - previous.x) + abs(current.y - previous.y)
		assert(distance == 1, "Path steps must be orthogonally adjacent.")


func advance(enemy: Enemy, delta_seconds: float) -> void:
	assert(enemy != null, "Enemy is required.")
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	if enemy.completed or enemy.defeated:
		return

	enemy.path_distance = minf(
		total_distance,
		enemy.path_distance
			+ enemy.speed_cells_per_second
			* enemy.get_movement_speed_multiplier()
			* delta_seconds
	)

	if enemy.path_distance >= total_distance:
		enemy.path_distance = total_distance
		enemy.completed = true


func get_grid_position(enemy: Enemy) -> Vector2i:
	assert(enemy != null, "Enemy is required.")

	if enemy.completed:
		return path[path.size() - 1]

	var segment_index := clampi(floori(enemy.path_distance), 0, path.size() - 2)
	return path[segment_index]


func get_grid_space_position(enemy: Enemy) -> Vector2:
	assert(enemy != null, "Enemy is required.")

	if enemy.completed:
		return _cell_center(path[path.size() - 1])

	var segment_index := clampi(floori(enemy.path_distance), 0, path.size() - 2)
	var segment_t := enemy.path_distance - float(segment_index)
	var from_position := _cell_center(path[segment_index])
	var to_position := _cell_center(path[segment_index + 1])

	return from_position.lerp(to_position, segment_t)


func _cell_center(grid_position: Vector2i) -> Vector2:
	return Vector2(float(grid_position.x) + 0.5, float(grid_position.y) + 0.5)
