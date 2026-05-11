class_name EnemyDefinition
extends RefCounted

const ID_KEY := "id"
const DISPLAY_NAME_KEY := "display_name"
const SPEED_KEY := "speed_cells_per_second"
const MAX_HEALTH_KEY := "max_health"
const KILL_REWARD_KEY := "kill_reward"
const ARMOR_TYPE_KEY := "armor_type"
const RACE_TYPE_KEY := "race_type"
const SCHOOL_RESISTANCE_OVERRIDES_KEY := "school_resistance_overrides"

var id: String
var display_name: String
var speed_cells_per_second: float
var max_health: float
var kill_reward: int
var armor_type: int
var race_type: int
var school_resistance_overrides: Dictionary


func _init(
	new_id: String = "",
	new_display_name: String = "",
	new_speed_cells_per_second: float = 1.0,
	new_max_health: float = Enemy.DEFAULT_MAX_HEALTH,
	new_kill_reward: int = Enemy.DEFAULT_KILL_REWARD,
	new_armor_type: int = DamageTypes.ArmorType.HEAVY,
	new_race_type: int = DamageTypes.RaceType.BEAST,
	new_school_resistance_overrides: Dictionary = {}
) -> void:
	id = new_id
	display_name = new_display_name if not new_display_name.is_empty() else new_id
	speed_cells_per_second = new_speed_cells_per_second
	max_health = new_max_health
	kill_reward = new_kill_reward
	armor_type = new_armor_type
	race_type = new_race_type
	school_resistance_overrides = new_school_resistance_overrides.duplicate(true)


func create_enemy(enemy_id: String) -> Enemy:
	return Enemy.new(
		enemy_id,
		speed_cells_per_second,
		max_health,
		kill_reward,
		armor_type,
		race_type,
		school_resistance_overrides
	)


static func from_dictionary(data: Dictionary) -> EnemyDefinition:
	return EnemyDefinition.new(
		str(data.get(ID_KEY, "")),
		str(data.get(DISPLAY_NAME_KEY, data.get(ID_KEY, ""))),
		float(data.get(SPEED_KEY, 1.0)),
		float(data.get(MAX_HEALTH_KEY, Enemy.DEFAULT_MAX_HEALTH)),
		int(data.get(KILL_REWARD_KEY, Enemy.DEFAULT_KILL_REWARD)),
		armor_type_from_value(data.get(ARMOR_TYPE_KEY, DamageTypes.ArmorType.HEAVY)),
		race_type_from_value(data.get(RACE_TYPE_KEY, DamageTypes.RaceType.BEAST)),
		resistance_overrides_from_dictionary(data.get(SCHOOL_RESISTANCE_OVERRIDES_KEY, {}) as Dictionary)
	)


static func resistance_overrides_from_dictionary(data: Dictionary) -> Dictionary:
	var overrides := {}
	if data == null:
		return overrides

	for key in data.keys():
		var damage_school := damage_school_from_value(key)
		if damage_school >= 0:
			overrides[damage_school] = float(data[key])

	return overrides


static func armor_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"UNARMORED":
			return DamageTypes.ArmorType.UNARMORED
		"LIGHT":
			return DamageTypes.ArmorType.LIGHT
		"MEDIUM":
			return DamageTypes.ArmorType.MEDIUM
		"HEAVY":
			return DamageTypes.ArmorType.HEAVY
		"FORTIFIED":
			return DamageTypes.ArmorType.FORTIFIED
		"HERO":
			return DamageTypes.ArmorType.HERO

	return -1


static func race_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"BEAST":
			return DamageTypes.RaceType.BEAST
		"HUMANOID":
			return DamageTypes.RaceType.HUMANOID
		"UNDEAD":
			return DamageTypes.RaceType.UNDEAD
		"CONSTRUCT":
			return DamageTypes.RaceType.CONSTRUCT
		"ELEMENTAL_FIRE":
			return DamageTypes.RaceType.ELEMENTAL_FIRE
		"ELEMENTAL_FROST":
			return DamageTypes.RaceType.ELEMENTAL_FROST
		"PLANT":
			return DamageTypes.RaceType.PLANT
		"DEMON":
			return DamageTypes.RaceType.DEMON

	return -1


static func damage_school_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"PHYSICAL":
			return DamageTypes.DamageSchool.PHYSICAL
		"FROST":
			return DamageTypes.DamageSchool.FROST
		"FIRE":
			return DamageTypes.DamageSchool.FIRE
		"POISON":
			return DamageTypes.DamageSchool.POISON
		"LIGHTNING":
			return DamageTypes.DamageSchool.LIGHTNING
		"ARCANE":
			return DamageTypes.DamageSchool.ARCANE
		"SHADOW":
			return DamageTypes.DamageSchool.SHADOW

	return -1
