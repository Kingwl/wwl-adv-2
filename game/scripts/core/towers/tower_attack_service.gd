class_name TowerAttackService
extends RefCounted

var tower_config: TowerConfig
var targeting_service: TargetingService
var _next_projectile_sequence := 1


func _init(new_tower_config: TowerConfig = null, new_targeting_service: TargetingService = null) -> void:
	tower_config = new_tower_config if new_tower_config != null else TowerConfig.new()
	targeting_service = new_targeting_service if new_targeting_service != null else TargetingService.new()


func tick_tower(tower: GameTower, delta_seconds: float, enemies: Array, path_follower: PathFollower) -> AttackResult:
	assert(tower != null, "Tower is required.")
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")
	assert(path_follower != null, "Path follower is required.")

	tower.cooldown_remaining = maxf(0.0, tower.cooldown_remaining - delta_seconds)
	if tower.cooldown_remaining > 0.0:
		return AttackResult.failure(
			AttackResult.FailureReason.COOLDOWN,
			tower.id,
			"Tower is cooling down."
		)

	var stats := tower_config.get_stats(tower.tower_type, tower.tier)
	var target := targeting_service.select_target(tower, stats, enemies, path_follower)
	if target == null:
		return AttackResult.failure(
			AttackResult.FailureReason.NO_TARGET,
			tower.id,
			"No target in range."
		)

	var projectile := _build_projectile(tower, stats, target)
	tower.cooldown_remaining = stats.attack_interval

	return AttackResult.success(tower.id, target.id, projectile)


func _build_projectile(tower: GameTower, stats: TowerStats, target: Enemy) -> CombatProjectile:
	var projectile_id := "%s-projectile-%d" % [tower.id, _next_projectile_sequence]
	_next_projectile_sequence += 1

	return CombatProjectile.new(
		projectile_id,
		tower.id,
		target.id,
		tower.tower_type,
		Vector2(float(tower.grid_position.x) + 0.5, float(tower.grid_position.y) + 0.5),
		stats.projectile_speed_cells_per_second,
		stats.projectile_hit_radius_cells,
		stats.damage,
		stats.splash_radius_cells,
		stats.slow_multiplier,
		stats.slow_duration,
		CombatProjectile.DEFAULT_MAX_LIFETIME_SECONDS,
		stats.attack_type,
		stats.damage_school,
		stats.status_type,
		stats.status_duration,
		stats.status_move_speed_multiplier,
		stats.status_tick_interval,
		stats.status_tick_damage,
		stats.status_stack_policy,
		stats.effects
	)
