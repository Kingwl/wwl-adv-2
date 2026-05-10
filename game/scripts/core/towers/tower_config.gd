class_name TowerConfig
extends RefCounted

const DEFAULT_TOWER_DEFINITION_PATH := "res://data/towers/towers.json"

const VERSION_KEY := "version"
const TOWERS_KEY := "towers"
const ID_KEY := "id"
const TYPE_KEY := "type"
const DISPLAY_NAME_KEY := "display_name"
const DESCRIPTION_KEY := "description"
const VISUAL_TEST_ENABLED_KEY := "visual_test_enabled"
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
const PROJECTILE_KEY := "projectile"
const PROJECTILE_SPEED_KEY := "speed_cells_per_second"
const PROJECTILE_HIT_RADIUS_KEY := "hit_radius_cells"
const EFFECTS_KEY := "effects"
const EFFECT_TYPE_KEY := "type"
const EFFECT_DAMAGE_MULTIPLIER_KEY := "damage_multiplier"
const EFFECT_RADIUS_KEY := "radius_cells"
const EFFECT_DURATION_KEY := "duration"
const STATUS_TYPE_KEY := "status_type"
const STATUS_DURATION_KEY := "status_duration"
const STATUS_MOVE_SPEED_MULTIPLIER_KEY := "status_move_speed_multiplier"
const STATUS_TICK_INTERVAL_KEY := "status_tick_interval"
const STATUS_TICK_DAMAGE_KEY := "status_tick_damage"
const STATUS_STACK_POLICY_KEY := "status_stack_policy"
const EFFECT_MOVE_SPEED_MULTIPLIER_KEY := "move_speed_multiplier"
const EFFECT_TICK_INTERVAL_KEY := "tick_interval"
const EFFECT_TICK_DAMAGE_KEY := "tick_damage"
const STACK_POLICY_KEY := "stack_policy"

const DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND := 6.0
const DEFAULT_PROJECTILE_HIT_RADIUS_CELLS := 0.12

var tower_definitions: Dictionary
var damage_affinity_config := DamageAffinityConfig.new()


func _init(new_tower_definitions: Dictionary = {}) -> void:
	var definitions := (
		load_definitions_from_path(DEFAULT_TOWER_DEFINITION_PATH)
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
	var damage_school := get_damage_school(tower_type)
	var effects := _get_effects(tier_definition)
	var status_effect = _first_status_effect(effects)
	var status_type := _status_type_from_effect(status_effect)
	var status_duration := _status_duration_from_effect_or_legacy(tier_definition, status_effect)
	var status_move_speed_multiplier := _status_move_speed_multiplier_from_effect_or_legacy(tier_definition, status_effect)
	var status_tick_interval := _status_tick_interval_from_effect_or_legacy(tier_definition, status_effect)
	var status_tick_damage := _status_tick_damage_from_effect_or_legacy(tier_definition, status_effect)
	var status_stack_policy := _status_stack_policy_from_effect_or_legacy(tier_definition, status_effect)
	var projectile_definition := _get_projectile_definition(tower_type)

	return TowerStats.new(
		float(tier_definition.get(DAMAGE_KEY, 0.0)),
		float(tier_definition.get(RANGE_KEY, 1.0)),
		float(tier_definition.get(ATTACK_INTERVAL_KEY, 1.0)),
		weapon_type,
		attack_type,
		damage_school,
		get_attack_pattern(tower_type),
		_get_splash_radius_cells(tier_definition, effects),
		_slow_multiplier_from_status(tier_definition, status_type, status_move_speed_multiplier),
		_slow_duration_from_status(tier_definition, status_type, status_duration),
		status_type,
		status_duration,
		status_move_speed_multiplier,
		status_tick_interval,
		status_tick_damage,
		status_stack_policy,
		TowerStats.Targeting.FIRST,
		_resolve_effect_damage_types(effects, attack_type, damage_school),
		float(projectile_definition.get(PROJECTILE_SPEED_KEY, DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND)),
		float(projectile_definition.get(PROJECTILE_HIT_RADIUS_KEY, DEFAULT_PROJECTILE_HIT_RADIUS_CELLS))
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


func get_tower_types() -> Array:
	var tower_types := tower_definitions.keys()
	tower_types.sort()
	return tower_types


func get_tower_id(tower_type: GameTower.Type) -> String:
	var tower_definition := _get_tower_definition(tower_type)
	return str(tower_definition.get(ID_KEY, _tower_type_id(tower_type)))


func get_display_name(tower_type: GameTower.Type) -> String:
	var tower_definition := _get_tower_definition(tower_type)
	return str(tower_definition.get(DISPLAY_NAME_KEY, _tower_type_name(tower_type)))


func get_description(tower_type: GameTower.Type) -> String:
	var tower_definition := _get_tower_definition(tower_type)
	return str(tower_definition.get(DESCRIPTION_KEY, ""))


func get_tower_button_node_name(tower_type: GameTower.Type) -> String:
	return "%sTowerButton" % _pascal_case_id(get_tower_id(tower_type))


func get_tower_button_specs() -> Array:
	var specs := []
	for tower_type in get_tower_types():
		specs.append({
			"name": get_tower_id(tower_type),
			"tower_type": tower_type,
			"display_name": get_display_name(tower_type),
			"description": get_description(tower_type),
			"node_name": get_tower_button_node_name(tower_type),
			"node_path": "Hud/%s" % get_tower_button_node_name(tower_type),
		})

	return specs


func is_visual_test_enabled(tower_type: GameTower.Type) -> bool:
	var tower_definition := _get_tower_definition(tower_type)
	return bool(tower_definition.get(VISUAL_TEST_ENABLED_KEY, true))


func get_visual_test_tower_specs() -> Array:
	var specs := []
	for tower_type in get_tower_types():
		if is_visual_test_enabled(tower_type):
			specs.append({
				"name": get_tower_id(tower_type),
				"tower_type": tower_type,
				"display_name": get_display_name(tower_type),
			})

	return specs


func can_upgrade(tower: GameTower) -> bool:
	return tower != null and tower.tier < get_max_tier(tower.tower_type)


static func load_definitions_from_path(resource_path: String) -> Dictionary:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load tower definitions: %s" % resource_path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Tower definitions must be a JSON object: %s" % resource_path)
		return {}

	return definitions_from_dictionary(parsed as Dictionary)


static func definitions_from_dictionary(data: Dictionary) -> Dictionary:
	var definitions := {}
	var tower_entries := data.get(TOWERS_KEY, []) as Array
	if tower_entries == null:
		return definitions

	for candidate in tower_entries:
		var tower_data := candidate as Dictionary
		if tower_data == null:
			continue

		var tower_type := _tower_type_from_value(tower_data.get(TYPE_KEY, ""))
		definitions[tower_type] = _tower_definition_from_data(tower_data, tower_type)

	return definitions


static func validate_definitions(definitions: Dictionary) -> Array:
	var errors := []
	if definitions.is_empty():
		errors.append("At least one tower definition is required.")
		return errors

	for tower_type in definitions.keys():
		var tower_name := _tower_type_name(tower_type)
		var tower_definition := definitions[tower_type] as Dictionary
		if tower_definition == null:
			errors.append("%s definition must be a dictionary." % tower_name)
			continue

		_validate_projectile_definition(errors, tower_name, tower_definition)

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


func _get_projectile_definition(tower_type: GameTower.Type) -> Dictionary:
	var tower_definition := _get_tower_definition(tower_type)
	return tower_definition.get(PROJECTILE_KEY, {}) as Dictionary


static func _tower_definition_from_data(tower_data: Dictionary, tower_type: int) -> Dictionary:
	var projectile_data := tower_data.get(PROJECTILE_KEY, {}) as Dictionary
	var tiers := []
	for candidate in tower_data.get(TIERS_KEY, []):
		var tier_data := candidate as Dictionary
		if tier_data != null:
			tiers.append(_tier_definition_from_data(tier_data))

	return {
		ID_KEY: str(tower_data.get(ID_KEY, _tower_type_id(tower_type))),
		DISPLAY_NAME_KEY: str(tower_data.get(DISPLAY_NAME_KEY, _tower_type_name(tower_type))),
		DESCRIPTION_KEY: str(tower_data.get(DESCRIPTION_KEY, "")),
		WEAPON_TYPE_KEY: _weapon_type_from_value(tower_data.get(WEAPON_TYPE_KEY, _default_weapon_type(tower_type))),
		ATTACK_TYPE_KEY: _attack_type_from_value(tower_data.get(ATTACK_TYPE_KEY, -1)),
		DAMAGE_SCHOOL_KEY: _damage_school_from_value(tower_data.get(DAMAGE_SCHOOL_KEY, _default_damage_school(tower_type))),
		ATTACK_PATTERN_KEY: _attack_pattern_from_value(tower_data.get(ATTACK_PATTERN_KEY, _default_attack_pattern(tower_type))),
		VISUAL_TEST_ENABLED_KEY: bool(tower_data.get(VISUAL_TEST_ENABLED_KEY, true)),
		PROJECTILE_KEY: {
			PROJECTILE_SPEED_KEY: float(projectile_data.get(PROJECTILE_SPEED_KEY, DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND)),
			PROJECTILE_HIT_RADIUS_KEY: float(projectile_data.get(PROJECTILE_HIT_RADIUS_KEY, DEFAULT_PROJECTILE_HIT_RADIUS_CELLS)),
		},
		TIERS_KEY: tiers,
	}


static func _tier_definition_from_data(tier_data: Dictionary) -> Dictionary:
	var effects := []
	for candidate in tier_data.get(EFFECTS_KEY, []):
		var effect_data := candidate as Dictionary
		if effect_data != null:
			effects.append(_effect_definition_from_data(effect_data))

	var tier_definition := {
		DAMAGE_KEY: float(tier_data.get(DAMAGE_KEY, 0.0)),
		RANGE_KEY: float(tier_data.get(RANGE_KEY, 1.0)),
		ATTACK_INTERVAL_KEY: float(tier_data.get(ATTACK_INTERVAL_KEY, 1.0)),
		EFFECTS_KEY: effects,
	}
	if tier_data.has(UPGRADE_COST_KEY):
		tier_definition[UPGRADE_COST_KEY] = int(tier_data[UPGRADE_COST_KEY])
	if tier_data.has(UPGRADE_PREVIEW_KEY):
		tier_definition[UPGRADE_PREVIEW_KEY] = str(tier_data[UPGRADE_PREVIEW_KEY])

	return tier_definition


static func _effect_definition_from_data(effect_data: Dictionary) -> Dictionary:
	var effect_type := _effect_type_from_value(effect_data.get(EFFECT_TYPE_KEY, ""))
	var definition := {
		EFFECT_TYPE_KEY: effect_type,
		EFFECT_DAMAGE_MULTIPLIER_KEY: float(effect_data.get(EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)),
		EFFECT_RADIUS_KEY: float(effect_data.get(EFFECT_RADIUS_KEY, 0.0)),
		STATUS_TYPE_KEY: _status_type_from_value(effect_data.get(STATUS_TYPE_KEY, -1)),
		EFFECT_DURATION_KEY: float(effect_data.get(EFFECT_DURATION_KEY, 0.0)),
		EFFECT_MOVE_SPEED_MULTIPLIER_KEY: float(effect_data.get(EFFECT_MOVE_SPEED_MULTIPLIER_KEY, 1.0)),
		EFFECT_TICK_INTERVAL_KEY: float(effect_data.get(EFFECT_TICK_INTERVAL_KEY, 0.0)),
		EFFECT_TICK_DAMAGE_KEY: float(effect_data.get(EFFECT_TICK_DAMAGE_KEY, 0.0)),
		STATUS_STACK_POLICY_KEY: _stack_policy_from_value(effect_data.get(STACK_POLICY_KEY, -1)),
	}
	if effect_data.has(ATTACK_TYPE_KEY):
		definition[ATTACK_TYPE_KEY] = _attack_type_from_value(effect_data[ATTACK_TYPE_KEY])
	if effect_data.has(DAMAGE_SCHOOL_KEY):
		definition[DAMAGE_SCHOOL_KEY] = _damage_school_from_value(effect_data[DAMAGE_SCHOOL_KEY])

	return definition


func _get_effects(tier_definition: Dictionary) -> Array:
	if not tier_definition.has(EFFECTS_KEY):
		return _legacy_effects_from_tier(tier_definition)

	var effects := []
	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	for candidate in effect_definitions:
		var effect: TowerEffect = _effect_from_value(candidate)
		if effect != null:
			effects.append(effect)

	return effects


func _legacy_effects_from_tier(tier_definition: Dictionary) -> Array:
	var effects := []
	var splash_radius := float(tier_definition.get(SPLASH_RADIUS_KEY, 0.0))
	if splash_radius > 0.0:
		effects.append(TowerEffect.splash_damage(splash_radius))
	else:
		effects.append(TowerEffect.damage_primary())

	var status_type := _get_status_type(tier_definition)
	var status_duration := _get_status_duration(tier_definition)
	if status_type >= 0 and status_duration > 0.0:
		effects.append(TowerEffect.apply_status(
			status_type,
			status_duration,
			float(tier_definition.get(
				STATUS_MOVE_SPEED_MULTIPLIER_KEY,
				tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)
			)),
			float(tier_definition.get(STATUS_TICK_INTERVAL_KEY, 0.0)),
			float(tier_definition.get(STATUS_TICK_DAMAGE_KEY, 0.0)),
			-1,
			-1,
			int(tier_definition.get(STATUS_STACK_POLICY_KEY, -1))
		))

	return effects


static func _effect_from_value(value):
	if value is TowerEffect:
		var existing: TowerEffect = value
		return existing.duplicate_effect()

	var definition := value as Dictionary
	if definition == null:
		return null

	var effect_type := _effect_type_from_value(definition.get(EFFECT_TYPE_KEY, TowerEffect.EffectType.DAMAGE_PRIMARY))
	match effect_type:
		TowerEffect.EffectType.SPLASH_DAMAGE:
			return TowerEffect.splash_damage(
				float(definition.get(EFFECT_RADIUS_KEY, 0.0)),
				float(definition.get(EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)),
				_attack_type_from_value(definition.get(ATTACK_TYPE_KEY, -1)),
				_damage_school_from_value(definition.get(DAMAGE_SCHOOL_KEY, -1))
			)
		TowerEffect.EffectType.APPLY_STATUS:
			return TowerEffect.apply_status(
				_status_type_from_value(definition.get(STATUS_TYPE_KEY, -1)),
				float(definition.get(EFFECT_DURATION_KEY, definition.get(STATUS_DURATION_KEY, 0.0))),
				float(definition.get(EFFECT_MOVE_SPEED_MULTIPLIER_KEY, definition.get(STATUS_MOVE_SPEED_MULTIPLIER_KEY, 1.0))),
				float(definition.get(EFFECT_TICK_INTERVAL_KEY, definition.get(STATUS_TICK_INTERVAL_KEY, 0.0))),
				float(definition.get(EFFECT_TICK_DAMAGE_KEY, definition.get(STATUS_TICK_DAMAGE_KEY, 0.0))),
				_attack_type_from_value(definition.get(ATTACK_TYPE_KEY, -1)),
				_damage_school_from_value(definition.get(DAMAGE_SCHOOL_KEY, -1)),
				_stack_policy_from_value(definition.get(STATUS_STACK_POLICY_KEY, definition.get(STACK_POLICY_KEY, -1)))
			)

	return TowerEffect.damage_primary(
		float(definition.get(EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)),
		_attack_type_from_value(definition.get(ATTACK_TYPE_KEY, -1)),
		_damage_school_from_value(definition.get(DAMAGE_SCHOOL_KEY, -1))
	)


static func _validate_projectile_definition(errors: Array, tower_name: String, tower_definition: Dictionary) -> void:
	var projectile_definition := tower_definition.get(PROJECTILE_KEY, {}) as Dictionary
	if projectile_definition == null:
		errors.append("%s projectile must be a dictionary." % tower_name)
		return

	if float(projectile_definition.get(PROJECTILE_SPEED_KEY, DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND)) <= 0.0:
		errors.append("%s projectile speed_cells_per_second must be positive." % tower_name)
	if float(projectile_definition.get(PROJECTILE_HIT_RADIUS_KEY, DEFAULT_PROJECTILE_HIT_RADIUS_CELLS)) < 0.0:
		errors.append("%s projectile hit_radius_cells cannot be negative." % tower_name)


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
	if _status_move_speed_multiplier_from_tier(tier_definition) <= 0.0:
		errors.append("%s tier %d status_move_speed_multiplier must be positive." % [tower_name, tier_number])
	if _status_tick_interval_from_tier(tier_definition) < 0.0:
		errors.append("%s tier %d status_tick_interval cannot be negative." % [tower_name, tier_number])
	if _status_tick_damage_from_tier(tier_definition) < 0.0:
		errors.append("%s tier %d status_tick_damage cannot be negative." % [tower_name, tier_number])
	if (
		_status_tick_damage_from_tier(tier_definition) > 0.0
		and _status_tick_interval_from_tier(tier_definition) <= 0.0
	):
		errors.append("%s tier %d status_tick_interval must be positive when status_tick_damage is positive." % [tower_name, tier_number])

	if tier_definition.has(EFFECTS_KEY):
		var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
		if effect_definitions == null or effect_definitions.is_empty():
			errors.append("%s tier %d effects must include at least one effect." % [tower_name, tier_number])
		else:
			for index in range(effect_definitions.size()):
				_validate_effect_definition(errors, tower_name, tier_number, index + 1, effect_definitions[index])


static func _validate_effect_definition(
	errors: Array,
	tower_name: String,
	tier_number: int,
	effect_number: int,
	effect_definition
) -> void:
	var effect_type := _effect_type_from_value(_effect_value(effect_definition, EFFECT_TYPE_KEY, -1))
	if effect_type < 0:
		errors.append("%s tier %d effect %d type is invalid." % [tower_name, tier_number, effect_number])
		return

	if float(_effect_value(effect_definition, EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)) < 0.0:
		errors.append("%s tier %d effect %d damage_multiplier cannot be negative." % [tower_name, tier_number, effect_number])

	if (
		effect_type == TowerEffect.EffectType.SPLASH_DAMAGE
		and float(_effect_value(effect_definition, EFFECT_RADIUS_KEY, 0.0)) <= 0.0
	):
		errors.append("%s tier %d effect %d radius_cells must be positive for splash_damage." % [tower_name, tier_number, effect_number])

	if effect_type != TowerEffect.EffectType.APPLY_STATUS:
		return

	if _status_type_from_value(_effect_value(effect_definition, STATUS_TYPE_KEY, -1)) < 0:
		errors.append("%s tier %d effect %d status_type is required for apply_status." % [tower_name, tier_number, effect_number])
	if float(_effect_value(effect_definition, EFFECT_DURATION_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d effect %d duration must be positive for apply_status." % [tower_name, tier_number, effect_number])
	if float(_effect_value(effect_definition, EFFECT_MOVE_SPEED_MULTIPLIER_KEY, 1.0)) <= 0.0:
		errors.append("%s tier %d effect %d move_speed_multiplier must be positive." % [tower_name, tier_number, effect_number])
	if float(_effect_value(effect_definition, EFFECT_TICK_INTERVAL_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d effect %d tick_interval cannot be negative." % [tower_name, tier_number, effect_number])
	if float(_effect_value(effect_definition, EFFECT_TICK_DAMAGE_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d effect %d tick_damage cannot be negative." % [tower_name, tier_number, effect_number])
	if (
		float(_effect_value(effect_definition, EFFECT_TICK_DAMAGE_KEY, 0.0)) > 0.0
		and float(_effect_value(effect_definition, EFFECT_TICK_INTERVAL_KEY, 0.0)) <= 0.0
	):
		errors.append("%s tier %d effect %d tick_interval must be positive when tick_damage is positive." % [tower_name, tier_number, effect_number])


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

	var previous_splash := _get_splash_radius_from_tier(previous_definition)
	var next_splash := _get_splash_radius_from_tier(tier_definition)
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
	if float(tier_definition.get(SLOW_DURATION_KEY, 0.0)) > 0.0:
		return true
	if float(tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)) < 1.0:
		return true

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect == null:
		return false

	return (
		status_effect.status_type == StatusEvent.StatusType.SLOW
		and status_effect.move_speed_multiplier < 1.0
	)


static func _get_status_type(tier_definition: Dictionary) -> int:
	if tier_definition.has(STATUS_TYPE_KEY):
		return _status_type_from_value(tier_definition[STATUS_TYPE_KEY])

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.status_type

	return StatusEvent.StatusType.SLOW if _tier_has_slow(tier_definition) else -1


static func _get_status_duration(tier_definition: Dictionary) -> float:
	if tier_definition.has(STATUS_DURATION_KEY) or tier_definition.has(SLOW_DURATION_KEY):
		return float(tier_definition.get(STATUS_DURATION_KEY, tier_definition.get(SLOW_DURATION_KEY, 0.0)))

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.duration

	return 0.0


static func _first_status_effect_from_tier(tier_definition: Dictionary):
	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	if effect_definitions == null:
		return null

	for candidate in effect_definitions:
		var effect: TowerEffect = _effect_from_value(candidate)
		if effect != null and effect.effect_type == TowerEffect.EffectType.APPLY_STATUS:
			return effect

	return null


static func _status_move_speed_multiplier_from_tier(tier_definition: Dictionary) -> float:
	if tier_definition.has(STATUS_MOVE_SPEED_MULTIPLIER_KEY) or tier_definition.has(SLOW_MULTIPLIER_KEY):
		return float(tier_definition.get(STATUS_MOVE_SPEED_MULTIPLIER_KEY, tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)))

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.move_speed_multiplier

	return 1.0


static func _status_tick_interval_from_tier(tier_definition: Dictionary) -> float:
	if tier_definition.has(STATUS_TICK_INTERVAL_KEY):
		return float(tier_definition[STATUS_TICK_INTERVAL_KEY])

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.tick_interval

	return 0.0


static func _status_tick_damage_from_tier(tier_definition: Dictionary) -> float:
	if tier_definition.has(STATUS_TICK_DAMAGE_KEY):
		return float(tier_definition[STATUS_TICK_DAMAGE_KEY])

	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.tick_damage

	return 0.0


static func _get_splash_radius_from_tier(tier_definition: Dictionary) -> float:
	if tier_definition.has(SPLASH_RADIUS_KEY):
		return float(tier_definition[SPLASH_RADIUS_KEY])

	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	if effect_definitions == null:
		return 0.0

	for candidate in effect_definitions:
		if _effect_type_from_value(_effect_value(candidate, EFFECT_TYPE_KEY, -1)) == TowerEffect.EffectType.SPLASH_DAMAGE:
			return float(_effect_value(candidate, EFFECT_RADIUS_KEY, 0.0))

	return 0.0


func _get_splash_radius_cells(tier_definition: Dictionary, effects: Array) -> float:
	if tier_definition.has(SPLASH_RADIUS_KEY):
		return float(tier_definition[SPLASH_RADIUS_KEY])

	for candidate in effects:
		var effect := candidate as TowerEffect
		if effect != null and effect.effect_type == TowerEffect.EffectType.SPLASH_DAMAGE:
			return effect.radius_cells

	return 0.0


func _first_status_effect(effects: Array):
	for candidate in effects:
		var effect := candidate as TowerEffect
		if effect != null and effect.effect_type == TowerEffect.EffectType.APPLY_STATUS:
			return effect

	return null


func _resolve_effect_damage_types(effects: Array, attack_type: int, damage_school: int) -> Array:
	var resolved_effects := []
	for candidate in effects:
		var effect := candidate as TowerEffect
		if effect == null:
			continue

		var resolved := effect.duplicate_effect()
		resolved.attack_type = effect.resolved_attack_type(attack_type)
		resolved.damage_school = effect.resolved_damage_school(damage_school)
		resolved.stack_policy = effect.resolved_stack_policy()
		resolved_effects.append(resolved)

	return resolved_effects


func _status_type_from_effect(status_effect) -> int:
	if status_effect == null:
		return -1
	return status_effect.status_type


func _status_duration_from_effect_or_legacy(tier_definition: Dictionary, status_effect) -> float:
	if tier_definition.has(STATUS_DURATION_KEY) or tier_definition.has(SLOW_DURATION_KEY):
		return float(tier_definition.get(STATUS_DURATION_KEY, tier_definition.get(SLOW_DURATION_KEY, 0.0)))
	if status_effect != null:
		return status_effect.duration
	return 0.0


func _status_move_speed_multiplier_from_effect_or_legacy(tier_definition: Dictionary, status_effect) -> float:
	if tier_definition.has(STATUS_MOVE_SPEED_MULTIPLIER_KEY) or tier_definition.has(SLOW_MULTIPLIER_KEY):
		return float(tier_definition.get(STATUS_MOVE_SPEED_MULTIPLIER_KEY, tier_definition.get(SLOW_MULTIPLIER_KEY, 1.0)))
	if status_effect != null:
		return status_effect.move_speed_multiplier
	return 1.0


func _status_tick_interval_from_effect_or_legacy(tier_definition: Dictionary, status_effect) -> float:
	if tier_definition.has(STATUS_TICK_INTERVAL_KEY):
		return float(tier_definition[STATUS_TICK_INTERVAL_KEY])
	if status_effect != null:
		return status_effect.tick_interval
	return 0.0


func _status_tick_damage_from_effect_or_legacy(tier_definition: Dictionary, status_effect) -> float:
	if tier_definition.has(STATUS_TICK_DAMAGE_KEY):
		return float(tier_definition[STATUS_TICK_DAMAGE_KEY])
	if status_effect != null:
		return status_effect.tick_damage
	return 0.0


func _status_stack_policy_from_effect_or_legacy(tier_definition: Dictionary, status_effect) -> int:
	if tier_definition.has(STATUS_STACK_POLICY_KEY):
		return int(tier_definition[STATUS_STACK_POLICY_KEY])
	if status_effect != null:
		return status_effect.resolved_stack_policy()
	return -1


func _slow_multiplier_from_status(
	tier_definition: Dictionary,
	status_type: int,
	status_move_speed_multiplier: float
) -> float:
	if tier_definition.has(SLOW_MULTIPLIER_KEY):
		return float(tier_definition[SLOW_MULTIPLIER_KEY])
	return status_move_speed_multiplier if status_type == StatusEvent.StatusType.SLOW else 1.0


func _slow_duration_from_status(tier_definition: Dictionary, status_type: int, status_duration: float) -> float:
	if tier_definition.has(SLOW_DURATION_KEY):
		return float(tier_definition[SLOW_DURATION_KEY])
	return status_duration if status_type == StatusEvent.StatusType.SLOW else 0.0


static func _effect_value(effect_definition, key: String, default_value):
	if effect_definition is TowerEffect:
		var effect: TowerEffect = effect_definition
		match key:
			EFFECT_TYPE_KEY:
				return effect.effect_type
			EFFECT_DAMAGE_MULTIPLIER_KEY:
				return effect.damage_multiplier
			EFFECT_RADIUS_KEY:
				return effect.radius_cells
			STATUS_TYPE_KEY:
				return effect.status_type
			EFFECT_DURATION_KEY, STATUS_DURATION_KEY:
				return effect.duration
			EFFECT_MOVE_SPEED_MULTIPLIER_KEY, STATUS_MOVE_SPEED_MULTIPLIER_KEY:
				return effect.move_speed_multiplier
			EFFECT_TICK_INTERVAL_KEY, STATUS_TICK_INTERVAL_KEY:
				return effect.tick_interval
			EFFECT_TICK_DAMAGE_KEY, STATUS_TICK_DAMAGE_KEY:
				return effect.tick_damage
			ATTACK_TYPE_KEY:
				return effect.attack_type
			DAMAGE_SCHOOL_KEY:
				return effect.damage_school
			STATUS_STACK_POLICY_KEY:
				return effect.stack_policy
		return default_value

	var dictionary := effect_definition as Dictionary
	if dictionary == null:
		return default_value

	if key == STATUS_STACK_POLICY_KEY and dictionary.has(STACK_POLICY_KEY):
		return dictionary[STACK_POLICY_KEY]

	return dictionary.get(key, default_value)


static func _tower_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"SINGLE_TARGET", "single", "single_target":
			return GameTower.Type.SINGLE_TARGET
		"AREA", "area":
			return GameTower.Type.AREA
		"SLOW", "slow":
			return GameTower.Type.SLOW
		"FLAME", "flame":
			return GameTower.Type.FLAME
		"POISON", "poison":
			return GameTower.Type.POISON

	return -1


static func _weapon_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"BOW":
			return DamageTypes.WeaponType.BOW
		"CROSSBOW":
			return DamageTypes.WeaponType.CROSSBOW
		"CANNON":
			return DamageTypes.WeaponType.CANNON
		"BLADE":
			return DamageTypes.WeaponType.BLADE
		"SPELL":
			return DamageTypes.WeaponType.SPELL
		"HEROIC":
			return DamageTypes.WeaponType.HEROIC
		"CHAOS":
			return DamageTypes.WeaponType.CHAOS

	return -1


static func _attack_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"NORMAL":
			return DamageTypes.AttackType.NORMAL
		"PIERCE":
			return DamageTypes.AttackType.PIERCE
		"SIEGE":
			return DamageTypes.AttackType.SIEGE
		"MAGIC":
			return DamageTypes.AttackType.MAGIC
		"HERO":
			return DamageTypes.AttackType.HERO
		"CHAOS":
			return DamageTypes.AttackType.CHAOS

	return -1


static func _damage_school_from_value(value) -> int:
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


static func _attack_pattern_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"SINGLE_PROJECTILE":
			return DamageTypes.AttackPattern.SINGLE_PROJECTILE
		"SPLASH_PROJECTILE":
			return DamageTypes.AttackPattern.SPLASH_PROJECTILE
		"STATUS_PROJECTILE":
			return DamageTypes.AttackPattern.STATUS_PROJECTILE
		"STATUS_DOT":
			return DamageTypes.AttackPattern.STATUS_DOT
		"CHAIN":
			return DamageTypes.AttackPattern.CHAIN
		"AURA":
			return DamageTypes.AttackPattern.AURA
		"GROUND_AREA":
			return DamageTypes.AttackPattern.GROUND_AREA
		"MULTI_SHOT":
			return DamageTypes.AttackPattern.MULTI_SHOT
		"SUMMON_OR_TRAP":
			return DamageTypes.AttackPattern.SUMMON_OR_TRAP

	return -1


static func _status_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"SLOW":
			return StatusEvent.StatusType.SLOW
		"BURN":
			return StatusEvent.StatusType.BURN
		"POISON":
			return StatusEvent.StatusType.POISON

	return -1


static func _stack_policy_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"REFRESH":
			return StatusEffect.StackPolicy.REFRESH
		"STRONGEST":
			return StatusEffect.StackPolicy.STRONGEST
		"REPLACE":
			return StatusEffect.StackPolicy.REPLACE
		"STACK":
			return StatusEffect.StackPolicy.STACK
		"INDEPENDENT":
			return StatusEffect.StackPolicy.INDEPENDENT

	return -1


static func _effect_type_from_value(value) -> int:
	if value is int:
		return int(value)

	match str(value):
		"damage_primary":
			return TowerEffect.EffectType.DAMAGE_PRIMARY
		"splash_damage":
			return TowerEffect.EffectType.SPLASH_DAMAGE
		"apply_status":
			return TowerEffect.EffectType.APPLY_STATUS

	return -1


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
		GameTower.Type.POISON:
			return "POISON"

	return str(tower_type)


static func _tower_type_id(tower_type) -> String:
	match tower_type:
		GameTower.Type.SINGLE_TARGET:
			return "single"
		GameTower.Type.AREA:
			return "area"
		GameTower.Type.SLOW:
			return "slow"
		GameTower.Type.FLAME:
			return "flame"
		GameTower.Type.POISON:
			return "poison"

	return str(tower_type)


static func _default_weapon_type(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.AREA:
			return DamageTypes.WeaponType.CANNON
		GameTower.Type.SLOW, GameTower.Type.FLAME:
			return DamageTypes.WeaponType.SPELL
		GameTower.Type.POISON:
			return DamageTypes.WeaponType.CROSSBOW

	return DamageTypes.WeaponType.CROSSBOW


static func _default_damage_school(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.SLOW:
			return DamageTypes.DamageSchool.FROST
		GameTower.Type.FLAME:
			return DamageTypes.DamageSchool.FIRE
		GameTower.Type.POISON:
			return DamageTypes.DamageSchool.POISON

	return DamageTypes.DamageSchool.PHYSICAL


static func _default_attack_pattern(tower_type: GameTower.Type) -> int:
	match tower_type:
		GameTower.Type.AREA:
			return DamageTypes.AttackPattern.SPLASH_PROJECTILE
		GameTower.Type.SLOW:
			return DamageTypes.AttackPattern.STATUS_PROJECTILE
		GameTower.Type.FLAME:
			return DamageTypes.AttackPattern.STATUS_DOT
		GameTower.Type.POISON:
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


static func _pascal_case_id(value: String) -> String:
	var result := ""
	for part in value.split("_", false):
		for subpart in part.split("-", false):
			if subpart.is_empty():
				continue
			result += subpart.substr(0, 1).to_upper() + subpart.substr(1).to_lower()
	return result
