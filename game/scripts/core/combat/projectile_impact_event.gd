class_name ProjectileImpactEvent
extends RefCounted

var projectile_id: String
var tower_id: String
var target_enemy_id: String
var tower_type: GameTower.Type
var position: Vector2
var hit: bool


func _init(
	new_projectile_id: String,
	new_tower_id: String,
	new_target_enemy_id: String,
	new_tower_type: GameTower.Type,
	new_position: Vector2,
	new_hit: bool
) -> void:
	assert(not new_projectile_id.is_empty(), "Projectile id is required.")
	assert(not new_tower_id.is_empty(), "Tower id is required.")

	projectile_id = new_projectile_id
	tower_id = new_tower_id
	target_enemy_id = new_target_enemy_id
	tower_type = new_tower_type
	position = new_position
	hit = new_hit
