class_name EconomyConfig
extends RefCounted

const DEFAULT_ECONOMY_CONFIG_PATH := "res://data/economy/economy.json"
const DEFAULT_INITIAL_GOLD := 100
const DEFAULT_BASIC_TOWER_COST := 25
const DEFAULT_KILL_REWARD := 5
const DEFAULT_WAVE_CLEAR_REWARD := 20
const DEFAULT_TOWER_REMOVAL_REFUND_RATIO := 0.5

const INITIAL_GOLD_KEY := "initial_gold"
const DEFAULT_TOWER_BUILD_COST_KEY := "default_tower_build_cost"
const BASIC_TOWER_COST_KEY := "basic_tower_cost"
const DEFAULT_KILL_REWARD_KEY := "default_kill_reward"
const WAVE_CLEAR_REWARD_KEY := "wave_clear_reward"
const TOWER_REMOVAL_REFUND_RATIO_KEY := "tower_removal_refund_ratio"

var initial_gold: int
var basic_tower_cost: int
var default_kill_reward: int
var wave_clear_reward: int
var tower_removal_refund_ratio: float


func _init(
	new_initial_gold: int = DEFAULT_INITIAL_GOLD,
	new_basic_tower_cost: int = DEFAULT_BASIC_TOWER_COST,
	new_default_kill_reward: int = DEFAULT_KILL_REWARD,
	new_wave_clear_reward: int = DEFAULT_WAVE_CLEAR_REWARD,
	new_tower_removal_refund_ratio: float = DEFAULT_TOWER_REMOVAL_REFUND_RATIO
) -> void:
	assert(new_initial_gold >= 0, "Initial gold cannot be negative.")
	assert(new_basic_tower_cost > 0, "Basic tower cost must be positive.")
	assert(new_default_kill_reward > 0, "Default kill reward must be positive.")
	assert(new_wave_clear_reward > 0, "Wave clear reward must be positive.")
	assert(new_tower_removal_refund_ratio >= 0.0, "Tower removal refund ratio cannot be negative.")
	assert(new_tower_removal_refund_ratio <= 1.0, "Tower removal refund ratio cannot exceed 1.")

	initial_gold = new_initial_gold
	basic_tower_cost = new_basic_tower_cost
	default_kill_reward = new_default_kill_reward
	wave_clear_reward = new_wave_clear_reward
	tower_removal_refund_ratio = new_tower_removal_refund_ratio


static func load_from_path(resource_path: String) -> EconomyConfig:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load economy config: %s" % resource_path)
		return EconomyConfig.new()

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Economy config must be a JSON object: %s" % resource_path)
		return EconomyConfig.new()

	return from_dictionary(parsed as Dictionary)


static func from_dictionary(data: Dictionary) -> EconomyConfig:
	return EconomyConfig.new(
		int(data.get(INITIAL_GOLD_KEY, DEFAULT_INITIAL_GOLD)),
		int(data.get(
			DEFAULT_TOWER_BUILD_COST_KEY,
			data.get(BASIC_TOWER_COST_KEY, DEFAULT_BASIC_TOWER_COST)
		)),
		int(data.get(DEFAULT_KILL_REWARD_KEY, DEFAULT_KILL_REWARD)),
		int(data.get(WAVE_CLEAR_REWARD_KEY, DEFAULT_WAVE_CLEAR_REWARD)),
		float(data.get(TOWER_REMOVAL_REFUND_RATIO_KEY, DEFAULT_TOWER_REMOVAL_REFUND_RATIO))
	)
