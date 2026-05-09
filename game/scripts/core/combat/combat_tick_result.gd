class_name CombatTickResult
extends RefCounted

var delta_seconds: float
var attack_results: Array
var spawned_projectiles: Array
var projectile_impact_events: Array
var damage_events: Array
var status_events: Array
var damage_result: EnemyDamageResult
var spawned_enemies: Array
var wave_clear_events: Array
var all_waves_cleared: bool
var enemy_leak_events: Array
var lives_remaining: int
var game_won: bool
var game_failed: bool


func _init(
	new_delta_seconds: float = 0.0,
	new_attack_results: Array = [],
	new_damage_events: Array = [],
	new_status_events: Array = [],
	new_damage_result: EnemyDamageResult = null,
	new_spawned_enemies: Array = [],
	new_wave_clear_events: Array = [],
	new_all_waves_cleared: bool = false,
	new_enemy_leak_events: Array = [],
	new_lives_remaining: int = 0,
	new_game_won: bool = false,
	new_game_failed: bool = false,
	new_spawned_projectiles: Array = [],
	new_projectile_impact_events: Array = []
) -> void:
	assert(new_delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	delta_seconds = new_delta_seconds
	attack_results = new_attack_results.duplicate()
	spawned_projectiles = new_spawned_projectiles.duplicate()
	projectile_impact_events = new_projectile_impact_events.duplicate()
	damage_events = new_damage_events.duplicate()
	status_events = new_status_events.duplicate()
	damage_result = new_damage_result if new_damage_result != null else EnemyDamageResult.new()
	spawned_enemies = new_spawned_enemies.duplicate()
	wave_clear_events = new_wave_clear_events.duplicate()
	all_waves_cleared = new_all_waves_cleared
	enemy_leak_events = new_enemy_leak_events.duplicate()
	lives_remaining = new_lives_remaining
	game_won = new_game_won
	game_failed = new_game_failed
