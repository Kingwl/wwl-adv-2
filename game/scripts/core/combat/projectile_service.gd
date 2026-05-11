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
				true,
				projectile.tower_definition_id
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
	var damage_events := []
	for candidate in projectile.effects:
		var effect := candidate as TowerEffect
		if effect == null:
			continue

		match effect.effect_type:
			TowerEffect.EffectType.DAMAGE_PRIMARY:
				damage_events.append(_build_damage_event(projectile, projectile.target_enemy_id, effect))
			TowerEffect.EffectType.SPLASH_DAMAGE:
				damage_events.append_array(_build_splash_damage_events(projectile, effect, enemies, path_follower))

	return damage_events


func _build_splash_damage_events(
	projectile: CombatProjectile,
	effect: TowerEffect,
	enemies: Array,
	path_follower: PathFollower
) -> Array:
	var damage_events := []

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			continue

		var enemy_position := path_follower.get_grid_space_position(enemy)
		if projectile.position.distance_to(enemy_position) <= effect.radius_cells:
			damage_events.append(_build_damage_event(projectile, enemy.id, effect))

	return damage_events


func _build_damage_event(projectile: CombatProjectile, enemy_id: String, effect: TowerEffect) -> DamageEvent:
	return DamageEvent.new(
		enemy_id,
		projectile.damage * effect.damage_multiplier,
		projectile.tower_id,
		effect.resolved_attack_type(projectile.attack_type),
		effect.resolved_damage_school(projectile.damage_school)
	)


func _build_status_events(projectile: CombatProjectile, target: Enemy) -> Array:
	var status_events := []
	for candidate in projectile.effects:
		var effect := candidate as TowerEffect
		if effect == null or effect.effect_type != TowerEffect.EffectType.APPLY_STATUS:
			continue
		if effect.status_type < 0 or effect.duration <= 0.0:
			continue

		status_events.append(StatusEvent.new(
			target.id,
			effect.status_type,
			effect.duration,
			effect.move_speed_multiplier,
			projectile.tower_id,
			effect.tick_interval,
			effect.tick_damage,
			effect.resolved_attack_type(projectile.attack_type),
			effect.resolved_damage_school(projectile.damage_school),
			effect.resolved_stack_policy()
		))

	return status_events
