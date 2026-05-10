class_name CombatSimulation
extends RefCounted

const DEFAULT_FIXED_STEP_SECONDS := 1.0 / 60.0
const FLOAT_EPSILON := 0.000001

var towers: Array
var enemies: Array
var projectiles: Array
var path_follower: PathFollower
var fixed_step_seconds: float
var accumulator_seconds: float
var tower_attack_service: TowerAttackService
var projectile_service: ProjectileService
var enemy_damage_service: EnemyDamageService
var status_effect_service: StatusEffectService
var wave_spawner: WaveSpawner
var enemy_leak_service: EnemyLeakService
var player_life: PlayerLife
var game_won: bool
var game_failed: bool


func _init(
	new_towers: Array,
	new_enemies: Array,
	new_path_follower: PathFollower,
	new_fixed_step_seconds: float = DEFAULT_FIXED_STEP_SECONDS,
	new_tower_attack_service: TowerAttackService = null,
	new_enemy_damage_service: EnemyDamageService = null,
	new_wave_spawner: WaveSpawner = null,
	new_enemy_leak_service: EnemyLeakService = null,
	new_player_life: PlayerLife = null,
	new_projectile_service: ProjectileService = null,
	new_status_effect_service: StatusEffectService = null
) -> void:
	assert(new_path_follower != null, "Path follower is required.")
	assert(new_fixed_step_seconds > 0.0, "Fixed step seconds must be positive.")

	towers = new_towers.duplicate()
	enemies = new_enemies.duplicate()
	projectiles = []
	path_follower = new_path_follower
	fixed_step_seconds = new_fixed_step_seconds
	accumulator_seconds = 0.0
	tower_attack_service = new_tower_attack_service if new_tower_attack_service != null else TowerAttackService.new()
	projectile_service = new_projectile_service if new_projectile_service != null else ProjectileService.new()
	enemy_damage_service = new_enemy_damage_service if new_enemy_damage_service != null else EnemyDamageService.new()
	status_effect_service = new_status_effect_service if new_status_effect_service != null else StatusEffectService.new()
	wave_spawner = new_wave_spawner
	enemy_leak_service = new_enemy_leak_service if new_enemy_leak_service != null else EnemyLeakService.new()
	player_life = new_player_life if new_player_life != null else PlayerLife.new()
	game_won = false
	game_failed = false


func advance(delta_seconds: float) -> Array:
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	accumulator_seconds += delta_seconds
	var tick_results := []

	while accumulator_seconds + FLOAT_EPSILON >= fixed_step_seconds:
		tick_results.append(tick(fixed_step_seconds))
		accumulator_seconds -= fixed_step_seconds

		if accumulator_seconds < FLOAT_EPSILON:
			accumulator_seconds = 0.0

	return tick_results


func tick(delta_seconds: float) -> CombatTickResult:
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	if game_won or game_failed:
		return _build_tick_result(delta_seconds)

	var wave_spawn_result := _advance_wave_spawner(delta_seconds)
	_advance_enemies(delta_seconds)
	var enemy_leak_events := enemy_leak_service.collect_leak_events(enemies)
	player_life.apply_leak_events(enemy_leak_events)

	var attack_results := []
	var spawned_projectiles := []

	for candidate in towers:
		var tower := candidate as GameTower
		if tower == null:
			continue

		var attack_result := tower_attack_service.tick_tower(tower, delta_seconds, enemies, path_follower)
		attack_results.append(attack_result)

		if attack_result.succeeded and attack_result.projectile != null:
			projectiles.append(attack_result.projectile)
			spawned_projectiles.append(attack_result.projectile)

	var projectile_result := projectile_service.advance(projectiles, enemies, path_follower, delta_seconds)
	var status_advance_result := status_effect_service.advance_statuses(enemies, delta_seconds)
	projectiles = projectile_result.active_projectiles
	var damage_events := []
	damage_events.append_array(projectile_result.damage_events)
	damage_events.append_array(status_advance_result.damage_events)
	var status_events := projectile_result.status_events
	var damage_result := enemy_damage_service.apply_damage_events(enemies, damage_events)
	status_effect_service.apply_status_events(enemies, status_events)
	if player_life.failed:
		game_failed = true
	elif wave_spawn_result.all_waves_cleared:
		game_won = true

	return CombatTickResult.new(
		delta_seconds,
		attack_results,
		damage_events,
		status_events,
		damage_result,
		wave_spawn_result.spawned_enemies,
		wave_spawn_result.wave_clear_events,
		wave_spawn_result.all_waves_cleared,
		enemy_leak_events,
		player_life.lives,
		game_won,
		game_failed,
		spawned_projectiles,
		projectile_result.impact_events
	)


func _build_tick_result(delta_seconds: float) -> CombatTickResult:
	return CombatTickResult.new(
		delta_seconds,
		[],
		[],
		[],
		EnemyDamageResult.new(),
		[],
		[],
		wave_spawner != null and wave_spawner.all_waves_cleared,
		[],
		player_life.lives,
		game_won,
		game_failed,
		[],
		[]
	)


func _advance_wave_spawner(delta_seconds: float) -> WaveSpawnResult:
	if wave_spawner == null:
		return WaveSpawnResult.new()

	var wave_spawn_result := wave_spawner.advance(delta_seconds, enemies)
	enemies.append_array(wave_spawn_result.spawned_enemies)
	return wave_spawn_result


func _advance_enemies(delta_seconds: float) -> void:
	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null:
			continue

		path_follower.advance(enemy, delta_seconds)
