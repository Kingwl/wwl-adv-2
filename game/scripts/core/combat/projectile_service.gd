class_name ProjectileService
extends RefCounted


func advance(projectiles: Array, enemies: Array, path_follower: PathFollower, delta_seconds: float) -> ProjectileAdvanceResult:
	assert(path_follower != null, "Path follower is required.")
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	var active_projectiles := []
	var damage_events := []
	var status_events := []
	var impact_events := []
	var missed_projectile_ids := []

	for candidate in projectiles:
		var projectile := candidate as CombatProjectile
		if projectile == null or not projectile.active:
			continue

		projectile.elapsed_seconds += delta_seconds
		if projectile.elapsed_seconds > projectile.max_lifetime_seconds:
			projectile.active = false
			missed_projectile_ids.append(projectile.id)
			continue

		var target := _get_active_enemy(projectile.target_enemy_id, enemies)
		if target == null:
			projectile.active = false
			missed_projectile_ids.append(projectile.id)
			continue

		var target_position := path_follower.get_grid_space_position(target)
		var distance := projectile.position.distance_to(target_position)
		var travel_distance := projectile.speed_cells_per_second * delta_seconds

		if distance <= projectile.hit_radius_cells or travel_distance + projectile.hit_radius_cells >= distance:
			projectile.position = target_position
			projectile.active = false
			impact_events.append(ProjectileImpactEvent.new(
				projectile.id,
				projectile.tower_id,
				projectile.target_enemy_id,
				projectile.tower_type,
				projectile.position,
				true
			))
			damage_events.append_array(_build_damage_events(projectile, enemies, path_follower))
			status_events.append_array(_build_status_events(projectile, target))
			continue

		projectile.position = projectile.position.move_toward(target_position, travel_distance)
		active_projectiles.append(projectile)

	return ProjectileAdvanceResult.new(active_projectiles, damage_events, status_events, impact_events, missed_projectile_ids)


func _get_active_enemy(enemy_id: String, enemies: Array) -> Enemy:
	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy != null and enemy.id == enemy_id and not enemy.completed and not enemy.defeated:
			return enemy

	return null


func _build_damage_events(projectile: CombatProjectile, enemies: Array, path_follower: PathFollower) -> Array:
	if projectile.tower_type == GameTower.Type.AREA:
		return _build_area_damage_events(projectile, enemies, path_follower)

	return [DamageEvent.new(projectile.target_enemy_id, projectile.damage, projectile.tower_id)]


func _build_area_damage_events(projectile: CombatProjectile, enemies: Array, path_follower: PathFollower) -> Array:
	var damage_events := []

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			continue

		var enemy_position := path_follower.get_grid_space_position(enemy)
		if projectile.position.distance_to(enemy_position) <= projectile.splash_radius_cells:
			damage_events.append(DamageEvent.new(enemy.id, projectile.damage, projectile.tower_id))

	return damage_events


func _build_status_events(projectile: CombatProjectile, target: Enemy) -> Array:
	if projectile.tower_type != GameTower.Type.SLOW:
		return []

	return [
		StatusEvent.new(
			target.id,
			StatusEvent.StatusType.SLOW,
			projectile.slow_duration,
			projectile.slow_multiplier,
			projectile.tower_id
		)
	]
