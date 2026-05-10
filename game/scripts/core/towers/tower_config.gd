class_name TowerConfig
extends RefCounted

const TIERS_KEY := "tiers"
const DAMAGE_KEY := "damage"
const RANGE_KEY := "range_cells"
const ATTACK_INTERVAL_KEY := "attack_interval"
const SPLASH_RADIUS_KEY := "splash_radius_cells"
const SLOW_MULTIPLIER_KEY := "slow_multiplier"
const SLOW_DURATION_KEY := "slow_duration"
const UPGRADE_COST_KEY := "upgrade_cost"
const UPGRADE_PREVIEW_KEY := "upgrade_preview"
const WEAPON_TYPE_KEY := "weapon_type"
const ATTACK_TYPE_KEY := "attack_type"
const DAMAGE_SCHOOL_KEY := "damage_school"
const ATTACK_PATTERN_KEY := "attack_pattern"
const STATUS_TYPE_KEY := "status_type"
const STATUS_DURATION_KEY := "status_duration"
const STATUS_MOVE_SPEED_MULTIPLIER_KEY := "status_move_speed_multiplier"
const STATUS_TICK_INTERVAL_KEY := "status_tick_interval"
const STATUS_TICK_DAMAGE_KEY := "status_tick_damage"
const STATUS_STACK_POLICY_KEY := "status_stack_policy"

var tower_definitions: Dictionary
var damage_affinity_config := DamageAffinityConfig.new()


func _init(new_tower_definitions: Dictionary = {}) -> void:
	var definitions := (
		_default_tower_definitions()
		if new_tower_definitions.is_empty()
		else new_tower_definitions.duplicate(true)
	)
	var validation_errors := validate_definitions(definitions)
	assert(
		validation_errors.is_empty(),
		"Invalid tower config: %s" % "; ".join(validation_errors)
	)
	tower_definitions = definitions


func get_stats(tower_type: GameTower.Type, tier: int) -> TowerStats:
	var tier_definition := _get_tier_definition(tower_type, tier)
	var weapon_type := get_weapon_type(tower_type)
	var attack_type := get_attack_type(tower_type)
	return TowerStats.new(
		float(tier_definition.get(DAMAGE_KEY, 0.0)),
		float(tier_definition.get(RANGE_KEY, 1.0)),
		float(tier_definition.get(ATTACK_INTERVAL_KEY, 1.0)),
		weapon_type,
		attack_type,
		get_damage_school(tower_type),
		get_attack_pattern(tower_type),
		float(tier_definition.get(SPLASH_RADIUS_KEY, 0.0)),
		float(tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)),
		float(tier_definition.get(SLOW_DURATION_KEY, 0.0)),
		_get_status_type(tier_definition),
		_get_status_duration(tier_definition),
		float(tier_definition.get(
			STATUS_MOVE_SPEED_MULTIPLIER_KEY,
			tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)
		)),
		float(tier_definition.get(STATUS_TICK_INTERVAL_KEY, 0.0)),
		float(tier_definition.get(STATUS_TICK_DAMAGE_KEY, 0.0)),
		int(tier_definition.get(STATUS_STACK_POLICY_KEY, -1)),
		TowerStats.Targeting.FIRST
	)


func get_max_tier(tower_type: GameTower.Type) -> int:
	return _get_tiers(tower_type).size()


func get_upgrade_cost(tower_type: GameTower.Type, tier: int) -> int:
	assert(tier >= 1, "Tower tier must be at least 1.")
	if tier >= get_max_tier(tower_type):
		return 0

	return int(_get_tier_definition(tower_type, tier).get(UPGRADE_COST_KEY, 0))


func get_upgrade_preview(tower_type: GameTower.Type, tier: int) -> String:
	assert(tier >= 1, "Tower tier must be at least 1.")
	if tier >= get_max_tier(tower_type):
		return "Max tier reached"

	var tier_definition := _get_tier_definition(tower_type, tier)
	if tier_definition.has(UPGRADE_PREVIEW_KEY):
		return str(tier_definition[UPGRADE_PREVIEW_KEY])

	var current := get_stats(tower_type, tier)
	var next := get_stats(tower_type, tier + 1)
	return "Damage %s / Range %s" % [
		_format_positive_delta(next.damage - current.damage),
		_format_positive_delta(next.range_cells - current.range_cells),
	]


func get_weapon_type(tower_type: GameTower.Type) -> int:
	var tower_definition := _get_tower_definition(tower_type)
	return int(tower_definition.get(WEAPON_TYPE_KEY, _default_weapon_type(tower_type)))


func get_attack_type(tower_type: GameTower.Type) -> int:
	var tower_definition := _get_tower_definition(tower_type)
	if tower_definition.has(ATTACK_TYPE_KEY):
		return int(tower_definition[ATTACK_TYPE_KEY])
	return damage_affinity_config.get_attack_type_for_weapon(get_weapon_type(tower_type))


func get_damage_school(tower_type: GameTower.Type) -> int:
	var tower_definition := _get_tower_definition(tower_type)
	return int(tower_definition.get(DAMAGE_SCHOOL_KEY, _default_damage_school(tower_type)))


func get_attack_pattern(tower_type: GameTower.Type) -> int:
	var tower_definition := _get_tower_definition(tower_type)
	return int(tower_definition.get(ATTACK_PATTERN_KEY, _default_attack_pattern(tower_type)))


func can_upgrade(tower: GameTower) -> bool:
	return tower != null and tower.tier < get_max_tier(tower.tower_type)


static func validate_definitions(definitions: Dictionary) -> Array:
	var errors := []
	for tower_type in definitions.keys():
		var tower_name := _tower_type_name(tower_type)
		var tower_definition := definitions[tower_type] as Dictionary
		if tower_definition == null:
			errors.append("%s definition must be a dictionary." % tower_name)
			continue

		var tiers := tower_definition.get(TIERS_KEY, []) as Array
		if tiers.is_empty():
			errors.append("%s tiers are required." % tower_name)
			continue

		for index in range(tiers.size()):
			var tier_number := index + 1
			var tier_definition := tiers[index] as Dictionary
			if tier_definition == null:
				errors.append("%s tier %d must be a dictionary." % [tower_name, tier_number])
				continue

			_validate_tier_stats(errors, tower_name, tier_number, tier_definition)
			_validate_tier_upgrade_cost(errors, tower_name, tier_number, tier_definition, index == tiers.size() - 1)
			if index > 0:
				var previous_definition := tiers[index - 1] as Dictionary
				if previous_definition != null:
					_validate_tier_growth(errors, tower_name, tier_number, previous_definition, tier_definition)

	return errors


func _get_tier_definition(tower_type: GameTower.Type, tier: int) -> Dictionary:
	assert(tier >= 1, "Tower tier must be at least 1.")
	var tiers := _get_tiers(tower_type)
	assert(tier <= tiers.size(), "Tower tier is not configured.")
	return tiers[tier - 1] as Dictionary


func _get_tiers(tower_type: GameTower.Type) -> Array:
	var tower_definition := _get_tower_definition(tower_type)
	var tiers := tower_definition.get(TIERS_KEY, []) as Array
	assert(not tiers.is_empty(), "Tower tiers are required.")
	return tiers


func _get_tower_definition(tower_type: GameTower.Type) -> Dictionary:
	assert(tower_definitions.has(tower_type), "Tower type is not configured.")
	return tower_definitions[tower_type] as Dictionary


func _default_tower_definitions() -> Dictionary:
	return {
		GameTower.Type.SINGLE_TARGET: {
			WEAPON_TYPE_KEY: DamageTypes.WeaponType.CROSSBOW,
			DAMAGE_SCHOOL_KEY: DamageTypes.DamageSchool.PHYSICAL,
			ATTACK_PATTERN_KEY: DamageTypes.AttackPattern.SINGLE_PROJECTILE,
			TIERS_KEY: [
				_tier(10.0, 2.5, 1.0, 0.0, 1.0, 0.0, 40),
				_tier(18.0, 2.75, 0.9, 0.0, 1.0, 0.0, 70),
				_tier(30.0, 3.0, 0.8),
			],
		},
		GameTower.Type.AREA: {
			WEAPON_TYPE_KEY: DamageTypes.WeaponType.CANNON,
			DAMAGE_SCHOOL_KEY: DamageTypes.DamageSchool.PHYSICAL,
			ATTACK_PATTERN_KEY: DamageTypes.AttackPattern.SPLASH_PROJECTILE,
			TIERS_KEY: [
				_tier(6.0, 2.0, 1.4, 0.75, 1.0, 0.0, 45),
				_tier(10.0, 2.15, 1.3, 0.95, 1.0, 0.0, 75),
				_tier(16.0, 2.35, 1.2, 1.15),
			],
		},
		GameTower.Type.SLOW: {
			WEAPON_TYPE_KEY: DamageTypes.WeaponType.SPELL,
			DAMAGE_SCHOOL_KEY: DamageTypes.DamageSchool.FROST,
			ATTACK_PATTERN_KEY: DamageTypes.AttackPattern.STATUS_PROJECTILE,
			TIERS_KEY: [
				_tier(3.0, 2.25, 1.2, 0.0, 0.6, 1.5, 35, StatusEvent.StatusType.SLOW, 1.5, 0.0, 0.0, 0.6, StatusEffect.StackPolicy.STRONGEST),
				_tier(5.0, 2.45, 1.15, 0.0, 0.55, 2.0, 65, StatusEvent.StatusType.SLOW, 2.0, 0.0, 0.0, 0.55, StatusEffect.StackPolicy.STRONGEST),
				_tier(8.0, 2.7, 1.1, 0.0, 0.5, 2.5, 0, StatusEvent.StatusType.SLOW, 2.5, 0.0, 0.0, 0.5, StatusEffect.StackPolicy.STRONGEST),
			],
		},
		GameTower.Type.FLAME: {
			WEAPON_TYPE_KEY: DamageTypes.WeaponType.SPELL,
			DAMAGE_SCHOOL_KEY: DamageTypes.DamageSchool.FIRE,
			ATTACK_PATTERN_KEY: DamageTypes.AttackPattern.STATUS_DOT,
			TIERS_KEY: [
				_tier(4.0, 2.2, 1.25, 0.0, 1.0, 0.0, 45, StatusEvent.StatusType.BURN, 3.0, 1.0, 2.0, 1.0, StatusEffect.StackPolicy.REFRESH),
				_tier(7.0, 2.45, 1.2, 0.0, 1.0, 0.0, 75, StatusEvent.StatusType.BURN, 3.5, 1.0, 3.0, 1.0, StatusEffect.StackPolicy.REFRESH),
				_tier(11.0, 2.75, 1.15, 0.0, 1.0, 0.0, 0, StatusEvent.StatusType.BURN, 4.0, 1.0, 4.0, 1.0, StatusEffect.StackPolicy.REFRESH),
			],
		},
	}


func _tier(
	damage: float,
	range_cells: float,
	attack_interval: float,
	splash_radius_cells: float = 0.0,
	slow_multiplier: float = 1.0,
	slow_duration: float = 0.0,
	upgrade_cost: int = 0,
	status_type: int = -1,
	status_duration: float = 0.0,
	status_tick_interval: float = 0.0,
	status_tick_damage: float = 0.0,
	status_move_speed_multiplier: float = 1.0,
	status_stack_policy: int = -1
) -> Dictionary:
	return {
		DAMAGE_KEY: damage,
		RANGE_KEY: range_cells,
		ATTACK_INTERVAL_KEY: attack_interval,
		SPLASH_RADIUS_KEY: splash_radius_cells,
		SLOW_MULTIPLIER_KEY: slow_multiplier,
		SLOW_DURATION_KEY: slow_duration,
		UPGRADE_COST_KEY: upgrade_cost,
		STATUS_TYPE_KEY: status_type,
		STATUS_DURATION_KEY: status_duration,
		STATUS_TICK_INTERVAL_KEY: status_tick_interval,
		STATUS_TICK_DAMAGE_KEY: status_tick_damage,
		STATUS_MOVE_SPEED_MULTIPLIER_KEY: status_move_speed_multiplier,
		STATUS_STACK_POLICY_KEY: status_stack_policy,
	}


static func _validate_tier_stats(
	errors: Array,
	tower_name: String,
	tier_number: int,
	tier_definition: Dictionary
) -> void:
	if float(tier_definition.get(DAMAGE_KEY, -1.0)) < 0.0:
		errors.append("%s tier %d damage cannot be negative." % [tower_name, tier_number])
	if float(tier_definition.get(RANGE_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d range_cells must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(ATTACK_INTERVAL_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d attack_interval must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(SPLASH_RADIUS_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d splash_radius_cells cannot be negative." % [tower_name, tier_number])
	if float(tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)) <= 0.0:
		errors.append("%s tier %d slow_multiplier must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(SLOW_DURATION_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d slow_duration cannot be negative." % [tower_name, tier_number])
	if _get_status_type(tier_definition) >= 0 and _get_status_duration(tier_definition) <= 0.0:
		errors.append("%s tier %d status_duration must be positive when status_type is configured." % [tower_name, tier_number])
	if float(tier_definition.get(STATUS_MOVE_SPEED_MULTIPLIER_KEY, 1.0)) <= 0.0:
		errors.append("%s tier %d status_move_speed_multiplier must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(STATUS_TICK_INTERVAL_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d status_tick_interval cannot be negative." % [tower_name, tier_number])
	if float(tier_definition.get(STATUS_TICK_DAMAGE_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d status_tick_damage cannot be negative." % [tower_name, tier_number])
	if (
		float(tier_definition.get(STATUS_TICK_DAMAGE_KEY, 0.0)) > 0.0
		and float(tier_definition.get(STATUS_TICK_INTERVAL_KEY, 0.0)) <= 0.0
	):
		errors.append("%s tier %d status_tick_interval must be positive when status_tick_damage is positive." % [tower_name, tier_number])


static func _validate_tier_upgrade_cost(
	errors: Array,
	tower_name: String,
	tier_number: int,
	tier_definition: Dictionary,
	is_max_tier: bool
) -> void:
	var upgrade_cost := int(tier_definition.get(UPGRADE_COST_KEY, 0))
	if is_max_tier:
		if upgrade_cost != 0:
			errors.append("%s max tier cannot define upgrade_cost." % tower_name)
		return

	if upgrade_cost <= 0:
		errors.append("%s tier %d upgrade_cost must be positive." % [tower_name, tier_number])


static func _validate_tier_growth(
	errors: Array,
	tower_name: String,
	tier_number: int,
	previous_definition: Dictionary,
	tier_definition: Dictionary
) -> void:
	var previous_damage := float(previous_definition.get(DAMAGE_KEY, 0.0))
	var next_damage := float(tier_definition.get(DAMAGE_KEY, 0.0))
	if next_damage <= previous_damage:
		errors.append("%s tier %d damage must be greater than tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_range := float(previous_definition.get(RANGE_KEY, 0.0))
	var next_range := float(tier_definition.get(RANGE_KEY, 0.0))
	if next_range <= previous_range:
		errors.append("%s tier %d range_cells must be greater than tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_splash := float(previous_definition.get(SPLASH_RADIUS_KEY, 0.0))
	var next_splash := float(tier_definition.get(SPLASH_RADIUS_KEY, 0.0))
	if previous_splash <= 0.0 and next_splash > 0.0:
		errors.append("%s tier %d cannot add splash to a tower that did not have splash at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_has_slow := _tier_has_slow(previous_definition)
	var next_has_slow := _tier_has_slow(tier_definition)
	if not previous_has_slow and next_has_slow:
		errors.append("%s tier %d cannot add slow to a tower that did not have slow at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_status_type := _get_status_type(previous_definition)
	var next_status_type := _get_status_type(tier_definition)
	if previous_status_type < 0 and next_status_type >= 0:
		errors.append("%s tier %d cannot add status to a tower that did not have status at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])
	if previous_status_type >= 0 and next_status_type >= 0 and previous_status_type != next_status_type:
		errors.append("%s tier %d cannot change status type from tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])


static func _tier_has_slow(tier_definition: Dictionary) -> bool:
	return (
		float(tier_definition.get(SLOW_DURATION_KEY, 0.0)) > 0.0
		or float(tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)) < 1.0
	)


static func _get_status_type(tier_definition: Dictionary) -> int:
	return int(tier_definition.get(STATUS_TYPE_KEY, StatusEvent.StatusType.SLOW if _tier_has_slow(tier_definition) else -1))


static func _get_status_duration(tier_definition: Dictionary) -> float:
	return float(tier_definition.get(STATUS_DURATION_KEY, tier_definition.get(SLOW_DURATION_KEY, 0.0)))


static func _tower_type_name(tower_type) -> String:
	match tower_type:
		GameTower.Type.SINGLE_TARGET:
			return "SINGLE_TARGET"
		GameTower.Type.AREA:
			return "AREA"
		GameTower.Type.SLOW:
			return "SLOW"
		GameTower.Type.FLAME:
			return "FLAME"

	return str(tower_type)


static func _default_weapon_type(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.AREA:
			return DamageTypes.WeaponType.CANNON
		GameTower.Type.SLOW, GameTower.Type.FLAME:
			return DamageTypes.WeaponType.SPELL

	return DamageTypes.WeaponType.CROSSBOW


static func _default_damage_school(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.SLOW:
			return DamageTypes.DamageSchool.FROST
		GameTower.Type.FLAME:
			return DamageTypes.DamageSchool.FIRE

	return DamageTypes.DamageSchool.PHYSICAL


static func _default_attack_pattern(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.AREA:
			return DamageTypes.AttackPattern.SPLASH_PROJECTILE
		GameTower.Type.SLOW:
			return DamageTypes.AttackPattern.STATUS_PROJECTILE
		GameTower.Type.FLAME:
			return DamageTypes.AttackPattern.STATUS_DOT

	return DamageTypes.AttackPattern.SINGLE_PROJECTILE


static func _format_positive_delta(delta: float) -> String:
	var rounded := snappedf(delta, 0.01)
	if is_equal_approx(rounded, roundf(rounded)):
		return "+%d" % int(roundf(rounded))

	var text := "%.2f" % rounded
	while text.ends_with("0"):
		text = text.left(text.length() - 1)
	if text.ends_with("."):
		text = text.left(text.length() - 1)
	return "+%s" % text
