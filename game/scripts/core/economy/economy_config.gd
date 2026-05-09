class_name EconomyConfig
extends RefCounted

const DEFAULT_INITIAL_GOLD := 100
const DEFAULT_BASIC_TOWER_COST := 25
const DEFAULT_KILL_REWARD := 5
const DEFAULT_WAVE_CLEAR_REWARD := 20

var initial_gold: int
var basic_tower_cost: int
var default_kill_reward: int
var wave_clear_reward: int


func _init(
	new_initial_gold: int = DEFAULT_INITIAL_GOLD,
	new_basic_tower_cost: int = DEFAULT_BASIC_TOWER_COST,
	new_default_kill_reward: int = DEFAULT_KILL_REWARD,
	new_wave_clear_reward: int = DEFAULT_WAVE_CLEAR_REWARD
) -> void:
	assert(new_initial_gold >= 0, "Initial gold cannot be negative.")
	assert(new_basic_tower_cost > 0, "Basic tower cost must be positive.")
	assert(new_default_kill_reward > 0, "Default kill reward must be positive.")
	assert(new_wave_clear_reward > 0, "Wave clear reward must be positive.")

	initial_gold = new_initial_gold
	basic_tower_cost = new_basic_tower_cost
	default_kill_reward = new_default_kill_reward
	wave_clear_reward = new_wave_clear_reward
