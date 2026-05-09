class_name WaveDefinition
extends RefCounted

var wave_id: String
var enemy_count: int
var spawn_interval_seconds: float
var enemy_max_health: float
var enemy_speed_cells_per_second: float
var enemy_kill_reward: int
var clear_reward_gold: int


func _init(
	new_wave_id: String,
	new_enemy_count: int,
	new_spawn_interval_seconds: float,
	new_enemy_max_health: float,
	new_enemy_speed_cells_per_second: float,
	new_enemy_kill_reward: int,
	new_clear_reward_gold: int
) -> void:
	assert(not new_wave_id.is_empty(), "Wave id is required.")
	assert(new_enemy_count > 0, "Enemy count must be positive.")
	assert(new_spawn_interval_seconds > 0.0, "Spawn interval must be positive.")
	assert(new_enemy_max_health > 0.0, "Enemy max health must be positive.")
	assert(new_enemy_speed_cells_per_second > 0.0, "Enemy speed must be positive.")
	assert(new_enemy_kill_reward >= 0, "Enemy kill reward cannot be negative.")
	assert(new_clear_reward_gold >= 0, "Clear reward gold cannot be negative.")

	wave_id = new_wave_id
	enemy_count = new_enemy_count
	spawn_interval_seconds = new_spawn_interval_seconds
	enemy_max_health = new_enemy_max_health
	enemy_speed_cells_per_second = new_enemy_speed_cells_per_second
	enemy_kill_reward = new_enemy_kill_reward
	clear_reward_gold = new_clear_reward_gold
