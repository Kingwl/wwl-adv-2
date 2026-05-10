class_name CombatProjectile
extends RefCounted

const DEFAULT_MAX_LIFETIME_SECONDS := 3.0

var id: String
var tower_id: String
var target_enemy_id: String
var tower_type: GameTower.Type
var position: Vector2
var speed_cells_per_second: float
var hit_radius_cells: float
var damage: float
var attack_type: int
var damage_school: int
var splash_radius_cells: float
var slow_multiplier: float
var slow_duration: float
var status_type: int
var status_duration: float
var status_move_speed_multiplier: float
var status_tick_interval: float
var status_tick_damage: float
var status_stack_policy: int
var effects: Array
var elapsed_seconds: float
var max_lifetime_seconds: float
var active: bool


func _init(
	new_id: String,
	new_tower_id: String,
	new_target_enemy_id: String,
	new_tower_type: GameTower.Type,
	new_position: Vector2,
	new_speed_cells_per_second: float,
	new_hit_radius_cells: float,
	new_damage: float,
	new_splash_radius_cells: float = 0.0,
	new_slow_multiplier: float = 1.0,
	new_slow_duration: float = 0.0,
	new_max_lifetime_seconds: float = DEFAULT_MAX_LIFETIME_SECONDS,
	new_attack_type: int = -1,
	new_damage_school: int = -1,
	new_status_type: int = -1,
	new_status_duration: float = 0.0,
	new_status_move_speed_multiplier: float = 1.0,
	new_status_tick_interval: float = 0.0,
	new_status_tick_damage: float = 0.0,
	new_status_stack_policy: int = -1,
	new_effects: Array = []
) -> void:
	assert(not new_id.is_empty(), "Projectile id is required.")
	assert(not new_tower_id.is_empty(), "Tower id is required.")
	assert(not new_target_enemy_id.is_empty(), "Target enemy id is required.")
	assert(new_speed_cells_per_second > 0.0, "Projectile speed must be positive.")
	assert(new_hit_radius_cells >= 0.0, "Projectile hit radius cannot be negative.")
	assert(new_damage >= 0.0, "Projectile damage cannot be negative.")
	assert(new_splash_radius_cells >= 0.0, "Projectile splash radius cannot be negative.")
	assert(new_slow_multiplier > 0.0, "Projectile slow multiplier must be positive.")
	assert(new_slow_duration >= 0.0, "Projectile slow duration cannot be negative.")
	assert(new_max_lifetime_seconds > 0.0, "Projectile lifetime must be positive.")
	assert(new_status_duration >= 0.0, "Projectile status duration cannot be negative.")
	assert(new_status_move_speed_multiplier > 0.0, "Projectile status move speed multiplier must be positive.")
	assert(new_status_tick_interval >= 0.0, "Projectile status tick interval cannot be negative.")
	assert(new_status_tick_damage >= 0.0, "Projectile status tick damage cannot be negative.")

	id = new_id
	tower_id = new_tower_id
	target_enemy_id = new_target_enemy_id
	tower_type = new_tower_type
	position = new_position
	speed_cells_per_second = new_speed_cells_per_second
	hit_radius_cells = new_hit_radius_cells
	damage = new_damage
	attack_type = _default_attack_type(new_tower_type) if new_attack_type < 0 else new_attack_type
	damage_school = _default_damage_school(new_tower_type) if new_damage_school < 0 else new_damage_school
	splash_radius_cells = new_splash_radius_cells
	slow_multiplier = new_slow_multiplier
	slow_duration = new_slow_duration
	status_type = _default_status_type(new_tower_type, new_slow_duration) if new_status_type < 0 else new_status_type
	status_duration = new_slow_duration if new_status_duration <= 0.0 and status_type == StatusEvent.StatusType.SLOW else new_status_duration
	status_move_speed_multiplier = new_slow_multiplier if status_type == StatusEvent.StatusType.SLOW else new_status_move_speed_multiplier
	status_tick_interval = new_status_tick_interval
	status_tick_damage = new_status_tick_damage
	status_stack_policy = (
		StatusEvent._default_stack_policy(status_type)
		if new_status_stack_policy < 0 and status_type >= 0
		else new_status_stack_policy
	)
	effects = _duplicate_effects(new_effects)
	if effects.is_empty():
		effects = _build_legacy_effects()
	elapsed_seconds = 0.0
	max_lifetime_seconds = new_max_lifetime_seconds
	active = true


static func _default_attack_type(projectile_tower_type: GameTower.Type) -> int:
	match projectile_tower_type:
		GameTower.Type.AREA:
			return DamageTypes.AttackType.SIEGE
		GameTower.Type.SLOW, GameTower.Type.FLAME:
			return DamageTypes.AttackType.MAGIC

	return DamageTypes.AttackType.PIERCE


static func _default_damage_school(projectile_tower_type: GameTower.Type) -> int:
	match projectile_tower_type:
		GameTower.Type.SLOW:
			return DamageTypes.DamageSchool.FROST
		GameTower.Type.FLAME:
			return DamageTypes.DamageSchool.FIRE

	return DamageTypes.DamageSchool.PHYSICAL


static func _default_status_type(projectile_tower_type: GameTower.Type, projectile_slow_duration: float) -> int:
	if projectile_tower_type == GameTower.Type.SLOW and projectile_slow_duration > 0.0:
		return StatusEvent.StatusType.SLOW
	return -1


func _build_legacy_effects() -> Array:
	var result := []
	if splash_radius_cells > 0.0:
		result.append(TowerEffect.splash_damage(splash_radius_cells))
	else:
		result.append(TowerEffect.damage_primary())

	if status_type >= 0 and status_duration > 0.0:
		result.append(TowerEffect.apply_status(
			status_type,
			status_duration,
			status_move_speed_multiplier,
			status_tick_interval,
			status_tick_damage,
			-1,
			-1,
			status_stack_policy
		))

	return result


static func _duplicate_effects(source_effects: Array) -> Array:
	var result := []
	for candidate in source_effects:
		var effect := candidate as TowerEffect
		if effect != null:
			result.append(effect.duplicate_effect())

	return result
