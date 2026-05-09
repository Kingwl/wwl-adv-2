class_name TargetingService
extends RefCounted


func select_target(
	tower: GameTower,
	stats: TowerStats,
	enemies: Array,
	path_follower: PathFollower
) -> Enemy:
	assert(tower != null, "Tower is required.")
	assert(stats != null, "Tower stats are required.")
	assert(path_follower != null, "Path follower is required.")

	match stats.targeting:
		TowerStats.Targeting.FIRST:
			return _select_first(tower, stats, enemies, path_follower)

	return null


func _select_first(
	tower: GameTower,
	stats: TowerStats,
	enemies: Array,
	path_follower: PathFollower
) -> Enemy:
	var selected_enemy: Enemy = null
	var selected_path_distance := -INF

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			continue

		if not _is_in_range(tower, stats, enemy, path_follower):
			continue

		if enemy.path_distance > selected_path_distance:
			selected_enemy = enemy
			selected_path_distance = enemy.path_distance

	return selected_enemy


func _is_in_range(tower: GameTower, stats: TowerStats, enemy: Enemy, path_follower: PathFollower) -> bool:
	var tower_position := Vector2(float(tower.grid_position.x) + 0.5, float(tower.grid_position.y) + 0.5)
	var enemy_position := path_follower.get_grid_space_position(enemy)
	return tower_position.distance_to(enemy_position) <= stats.range_cells
