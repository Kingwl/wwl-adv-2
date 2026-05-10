class_name Enemy
extends RefCounted

const DEFAULT_MAX_HEALTH := 20.0
const DEFAULT_KILL_REWARD := 5

var id: String
var speed_cells_per_second: float
var max_health: float
var health: float
var kill_reward: int
var armor_type: int
var race_type: int
var school_resistance_overrides: Dictionary
var status_effects: Array
var path_distance: float
var completed: bool
var defeated: bool


func _init(
	new_id: String,
	new_speed_cells_per_second: float = 1.0,
	new_max_health: float = DEFAULT_MAX_HEALTH,
	new_kill_reward: int = DEFAULT_KILL_REWARD,
	new_armor_type: int = DamageTypes.ArmorType.HEAVY,
	new_race_type: int = DamageTypes.RaceType.BEAST,
	new_school_resistance_overrides: Dictionary = {}
) -> void:
	assert(not new_id.is_empty(), "Enemy id is required.")
	assert(new_speed_cells_per_second > 0.0, "Enemy speed must be positive.")
	assert(new_max_health > 0.0, "Enemy max health must be positive.")
	assert(new_kill_reward >= 0, "Enemy kill reward cannot be negative.")

	id = new_id
	speed_cells_per_second = new_speed_cells_per_second
	max_health = new_max_health
	health = max_health
	kill_reward = new_kill_reward
	armor_type = new_armor_type
	race_type = new_race_type
	school_resistance_overrides = new_school_resistance_overrides.duplicate(true)
	status_effects = []
	path_distance = 0.0
	completed = false
	defeated = false


func apply_damage(amount: float) -> bool:
	assert(amount >= 0.0, "Damage amount cannot be negative.")

	if defeated:
		return false

	health = maxf(0.0, health - amount)
	if health <= 0.0:
		defeated = true
		return true

	return false


func get_movement_speed_multiplier() -> float:
	var movement_speed_multiplier := 1.0

	for candidate in status_effects:
		var effect := candidate as StatusEffect
		if effect == null:
			continue

		movement_speed_multiplier = minf(movement_speed_multiplier, effect.move_speed_multiplier)

	return movement_speed_multiplier
