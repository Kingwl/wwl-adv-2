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
var splash_radius_cells: float
var slow_multiplier: float
var slow_duration: float
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
	new_max_lifetime_seconds: float = DEFAULT_MAX_LIFETIME_SECONDS
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

	id = new_id
	tower_id = new_tower_id
	target_enemy_id = new_target_enemy_id
	tower_type = new_tower_type
	position = new_position
	speed_cells_per_second = new_speed_cells_per_second
	hit_radius_cells = new_hit_radius_cells
	damage = new_damage
	splash_radius_cells = new_splash_radius_cells
	slow_multiplier = new_slow_multiplier
	slow_duration = new_slow_duration
	elapsed_seconds = 0.0
	max_lifetime_seconds = new_max_lifetime_seconds
	active = true
