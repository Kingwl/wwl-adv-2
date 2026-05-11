class_name TowerConfig
extends RefCounted

const DEFAULT_TOWER_DEFINITION_PATH := "res://data/towers/towers.json"

const VERSION_KEY := "version"
const TOWERS_KEY := "towers"
const ID_KEY := "id"
const TYPE_KEY := "type"
const DISPLAY_NAME_KEY := "display_name"
const DESCRIPTION_KEY := "description"
const BUILD_COST_KEY := "build_cost"
const VISUAL_TEST_ENABLED_KEY := "visual_test_enabled"
const VISUALS_KEY := "visuals"
const TOWER_TEXTURE_KEY := "tower"
const PROJECTILE_TEXTURES_KEY := "projectiles"
const IMPACT_TEXTURES_KEY := "impacts"
const TIERS_KEY := "tiers"
const DAMAGE_KEY := "damage"
const RANGE_KEY := "range_cells"
const ATTACK_INTERVAL_KEY := "attack_interval"
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
const EFFECT_MOVE_SPEED_MULTIPLIER_KEY := "move_speed_multiplier"
const EFFECT_TICK_INTERVAL_KEY := "tick_interval"
const EFFECT_TICK_DAMAGE_KEY := "tick_damage"
const STACK_POLICY_KEY := "stack_policy"

const DEFAULT_BUILD_COST := 25
const DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND := 6.0
const DEFAULT_PROJECTILE_HIT_RADIUS_CELLS := 0.12

var tower_definitions: Dictionary
var damage_affinity_config := DamageAffinityConfig.new()


func _init(new_tower_definitions: Dictionary = {}) -> void:
	var raw_definitions := (
		load_definitions_from_path(DEFAULT_TOWER_DEFINITION_PATH)
		if new_tower_definitions.is_empty()
		else new_tower_definitions.duplicate(true)
	)
	var definitions := normalize_definitions(raw_definitions)
	var validation_errors := validate_definitions(definitions)
	assert(
		validation_errors.is_empty(),
		"Invalid tower config: %s" % "; ".join(validation_errors)
	)
	tower_definitions = definitions


func get_stats(tower_type: int, tier: int) -> TowerStats:
	return get_stats_for_id(get_tower_id(tower_type), tier)


func get_stats_for_id(tower_id: String, tier: int) -> TowerStats:
	var tier_definition := _get_tier_definition_for_id(tower_id, tier)
	var weapon_type := get_weapon_type_for_id(tower_id)
	var attack_type := get_attack_type_for_id(tower_id)
	var damage_school := get_damage_school_for_id(tower_id)
	var effects := _get_effects(tier_definition)
	var status_effect = _first_status_effect(effects)
	var status_type := _status_type_from_effect(status_effect)
	var status_duration := _status_duration_from_effect(status_effect)
	var status_move_speed_multiplier := _status_move_speed_multiplier_from_effect(status_effect)
	var status_tick_interval := _status_tick_interval_from_effect(status_effect)
	var status_tick_damage := _status_tick_damage_from_effect(status_effect)
	var status_stack_policy := _status_stack_policy_from_effect(status_effect)
	var projectile_definition := _get_projectile_definition_for_id(tower_id)

	return TowerStats.new(
		float(tier_definition.get(DAMAGE_KEY, 0.0)),
		float(tier_definition.get(RANGE_KEY, 1.0)),
		float(tier_definition.get(ATTACK_INTERVAL_KEY, 1.0)),
		weapon_type,
		attack_type,
		damage_school,
		get_attack_pattern_for_id(tower_id),
		_get_splash_radius_cells(effects),
		_slow_multiplier_from_status(status_type, status_move_speed_multiplier),
		_slow_duration_from_status(status_type, status_duration),
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


func get_max_tier(tower_type: int) -> int:
	return get_max_tier_for_id(get_tower_id(tower_type))


func get_max_tier_for_id(tower_id: String) -> int:
	return _get_tiers_for_id(tower_id).size()


func get_upgrade_cost(tower_type: int, tier: int) -> int:
	return get_upgrade_cost_for_id(get_tower_id(tower_type), tier)


func get_upgrade_cost_for_id(tower_id: String, tier: int) -> int:
	assert(tier >= 1, "Tower tier must be at least 1.")
	if tier >= get_max_tier_for_id(tower_id):
		return 0

	return int(_get_tier_definition_for_id(tower_id, tier).get(UPGRADE_COST_KEY, 0))


func get_build_cost(tower_type: int, fallback_cost: int = DEFAULT_BUILD_COST) -> int:
	return get_build_cost_for_id(get_tower_id(tower_type), fallback_cost)


func get_build_cost_for_id(tower_id: String, fallback_cost: int = DEFAULT_BUILD_COST) -> int:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return int(tower_definition.get(BUILD_COST_KEY, fallback_cost))


func get_upgrade_preview(tower_type: int, tier: int) -> String:
	return get_upgrade_preview_for_id(get_tower_id(tower_type), tier)


func get_upgrade_preview_for_id(tower_id: String, tier: int) -> String:
	assert(tier >= 1, "Tower tier must be at least 1.")
	if tier >= get_max_tier_for_id(tower_id):
		return "Max tier reached"

	var tier_definition := _get_tier_definition_for_id(tower_id, tier)
	if tier_definition.has(UPGRADE_PREVIEW_KEY):
		return str(tier_definition[UPGRADE_PREVIEW_KEY])

	var current := get_stats_for_id(tower_id, tier)
	var next := get_stats_for_id(tower_id, tier + 1)
	return "Damage %s / Range %s" % [
		_format_positive_delta(next.damage - current.damage),
		_format_positive_delta(next.range_cells - current.range_cells),
	]


func get_weapon_type(tower_type: int) -> int:
	return get_weapon_type_for_id(get_tower_id(tower_type))


func get_weapon_type_for_id(tower_id: String) -> int:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return int(tower_definition.get(WEAPON_TYPE_KEY, _default_weapon_type(get_tower_type_for_id(tower_id))))


func get_attack_type(tower_type: int) -> int:
	return get_attack_type_for_id(get_tower_id(tower_type))


func get_attack_type_for_id(tower_id: String) -> int:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	if tower_definition.has(ATTACK_TYPE_KEY):
		return int(tower_definition[ATTACK_TYPE_KEY])
	return damage_affinity_config.get_attack_type_for_weapon(get_weapon_type_for_id(tower_id))


func get_damage_school(tower_type: int) -> int:
	return get_damage_school_for_id(get_tower_id(tower_type))


func get_damage_school_for_id(tower_id: String) -> int:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return int(tower_definition.get(DAMAGE_SCHOOL_KEY, _default_damage_school(get_tower_type_for_id(tower_id))))


func get_attack_pattern(tower_type: int) -> int:
	return get_attack_pattern_for_id(get_tower_id(tower_type))


func get_attack_pattern_for_id(tower_id: String) -> int:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return int(tower_definition.get(ATTACK_PATTERN_KEY, _default_attack_pattern(get_tower_type_for_id(tower_id))))


func get_tower_types() -> Array:
	var tower_types := []
	for tower_id in tower_definitions.keys():
		var tower_definition := tower_definitions[tower_id] as Dictionary
		if tower_definition == null:
			continue
		var tower_type := int(tower_definition.get(TYPE_KEY, -1))
		if tower_type >= 0:
			tower_types.append(tower_type)
	tower_types.sort()
	return tower_types


func get_tower_ids() -> Array:
	var tower_ids := []
	for tower_type in get_tower_types():
		tower_ids.append(get_tower_id(tower_type))
	var extra_ids := []
	for tower_id in tower_definitions.keys():
		var definition_id := String(tower_id)
		if not tower_ids.has(definition_id):
			extra_ids.append(definition_id)
	extra_ids.sort()
	tower_ids.append_array(extra_ids)
	return tower_ids


func get_tower_id(tower_type: int) -> String:
	for tower_id in tower_definitions.keys():
		var tower_definition := tower_definitions[tower_id] as Dictionary
		if tower_definition != null and int(tower_definition.get(TYPE_KEY, -1)) == int(tower_type):
			return str(tower_definition.get(ID_KEY, tower_id))
	return _tower_type_id(tower_type)


func get_tower_type_for_id(tower_id: String) -> int:
	if tower_definitions.has(tower_id):
		var tower_definition := tower_definitions[tower_id] as Dictionary
		if tower_definition != null:
			return int(tower_definition.get(TYPE_KEY, -1))
	return -1


func has_tower_id(tower_id: String) -> bool:
	return tower_definitions.has(tower_id)


func get_display_name(tower_type: int) -> String:
	return get_display_name_for_id(get_tower_id(tower_type))


func get_display_name_for_id(tower_id: String) -> String:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return str(tower_definition.get(DISPLAY_NAME_KEY, _tower_id_label(tower_id)))


func get_description(tower_type: int) -> String:
	return get_description_for_id(get_tower_id(tower_type))


func get_description_for_id(tower_id: String) -> String:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return str(tower_definition.get(DESCRIPTION_KEY, ""))


func get_tower_texture_path(tower_type: int) -> String:
	return get_tower_texture_path_for_id(get_tower_id(tower_type))


func get_tower_texture_path_for_id(tower_id: String) -> String:
	return str(_get_visuals_definition_for_id(tower_id).get(TOWER_TEXTURE_KEY, ""))


func get_projectile_texture_paths(tower_type: int) -> Array:
	return get_projectile_texture_paths_for_id(get_tower_id(tower_type))


func get_projectile_texture_paths_for_id(tower_id: String) -> Array:
	return (_get_visuals_definition_for_id(tower_id).get(PROJECTILE_TEXTURES_KEY, []) as Array).duplicate()


func get_impact_texture_paths(tower_type: int) -> Array:
	return get_impact_texture_paths_for_id(get_tower_id(tower_type))


func get_impact_texture_paths_for_id(tower_id: String) -> Array:
	return (_get_visuals_definition_for_id(tower_id).get(IMPACT_TEXTURES_KEY, []) as Array).duplicate()


func is_visual_test_enabled(tower_type: int) -> bool:
	return is_visual_test_enabled_for_id(get_tower_id(tower_type))


func is_visual_test_enabled_for_id(tower_id: String) -> bool:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return bool(tower_definition.get(VISUAL_TEST_ENABLED_KEY, true))


func can_upgrade(tower: GameTower) -> bool:
	return tower != null and tower.tier < get_max_tier_for_id(get_tower_id_for_runtime_tower(tower))


func get_tower_id_for_runtime_tower(tower: GameTower) -> String:
	if tower == null:
		return ""
	if not tower.definition_id.is_empty() and has_tower_id(tower.definition_id):
		return tower.definition_id
	var tower_id := get_tower_id(tower.tower_type)
	if has_tower_id(tower_id):
		return tower_id
	return tower.definition_id


static func load_definitions_from_path(resource_path: String) -> Dictionary:
	return TowerDefinitionParser.load_definitions_from_path(resource_path)


static func definitions_from_dictionary(data: Dictionary) -> Dictionary:
	return TowerDefinitionParser.definitions_from_dictionary(data)


static func validate_definitions(definitions: Dictionary) -> Array:
	return TowerDefinitionValidator.validate_definitions(normalize_definitions(definitions))


static func normalize_definitions(definitions: Dictionary) -> Dictionary:
	var normalized := {}
	for key in definitions.keys():
		var tower_definition := definitions[key] as Dictionary
		if tower_definition == null:
			normalized[key] = definitions[key]
			continue

		var tower_type := _tower_type_from_definition_key(key, tower_definition)
		var tower_id := str(tower_definition.get(ID_KEY, _tower_type_id(tower_type)))
		if tower_id.is_empty() or tower_id == "-1":
			tower_id = str(key)

		var normalized_definition := tower_definition.duplicate(true)
		normalized_definition[ID_KEY] = tower_id
		normalized_definition[TYPE_KEY] = tower_type
		normalized[tower_id] = normalized_definition

	return normalized


func _get_tier_definition(tower_type: int, tier: int) -> Dictionary:
	return _get_tier_definition_for_id(get_tower_id(tower_type), tier)


func _get_tier_definition_for_id(tower_id: String, tier: int) -> Dictionary:
	assert(tier >= 1, "Tower tier must be at least 1.")
	var tiers := _get_tiers_for_id(tower_id)
	assert(tier <= tiers.size(), "Tower tier is not configured.")
	return tiers[tier - 1] as Dictionary


func _get_tiers(tower_type: int) -> Array:
	return _get_tiers_for_id(get_tower_id(tower_type))


func _get_tiers_for_id(tower_id: String) -> Array:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	var tiers := tower_definition.get(TIERS_KEY, []) as Array
	assert(not tiers.is_empty(), "Tower tiers are required.")
	return tiers


func _get_tower_definition(tower_type: int) -> Dictionary:
	return _get_tower_definition_for_id(get_tower_id(tower_type))


func _get_tower_definition_for_id(tower_id: String) -> Dictionary:
	assert(tower_definitions.has(tower_id), "Tower id is not configured.")
	return tower_definitions[tower_id] as Dictionary


func _get_projectile_definition(tower_type: int) -> Dictionary:
	return _get_projectile_definition_for_id(get_tower_id(tower_type))


func _get_projectile_definition_for_id(tower_id: String) -> Dictionary:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return tower_definition.get(PROJECTILE_KEY, {}) as Dictionary


func _get_visuals_definition(tower_type: int) -> Dictionary:
	return _get_visuals_definition_for_id(get_tower_id(tower_type))


func _get_visuals_definition_for_id(tower_id: String) -> Dictionary:
	var tower_definition := _get_tower_definition_for_id(tower_id)
	return tower_definition.get(VISUALS_KEY, {}) as Dictionary


func _get_effects(tier_definition: Dictionary) -> Array:
	var effects := []
	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	for candidate in effect_definitions:
		var effect: TowerEffect = _effect_from_value(candidate)
		if effect != null:
			effects.append(effect)

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
				float(definition.get(EFFECT_DURATION_KEY, 0.0)),
				float(definition.get(EFFECT_MOVE_SPEED_MULTIPLIER_KEY, 1.0)),
				float(definition.get(EFFECT_TICK_INTERVAL_KEY, 0.0)),
				float(definition.get(EFFECT_TICK_DAMAGE_KEY, 0.0)),
				_attack_type_from_value(definition.get(ATTACK_TYPE_KEY, -1)),
				_damage_school_from_value(definition.get(DAMAGE_SCHOOL_KEY, -1)),
				_stack_policy_from_value(definition.get(STACK_POLICY_KEY, -1))
			)

	return TowerEffect.damage_primary(
		float(definition.get(EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)),
		_attack_type_from_value(definition.get(ATTACK_TYPE_KEY, -1)),
		_damage_school_from_value(definition.get(DAMAGE_SCHOOL_KEY, -1))
	)


static func _tier_has_slow(tier_definition: Dictionary) -> bool:
	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect == null:
		return false

	return (
		status_effect.status_type == StatusEvent.StatusType.SLOW
		and status_effect.move_speed_multiplier < 1.0
	)


static func _get_status_type(tier_definition: Dictionary) -> int:
	var status_effect = _first_status_effect_from_tier(tier_definition)
	if status_effect != null:
		return status_effect.status_type

	return -1


static func _first_status_effect_from_tier(tier_definition: Dictionary):
	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	if effect_definitions == null:
		return null

	for candidate in effect_definitions:
		var effect: TowerEffect = _effect_from_value(candidate)
		if effect != null and effect.effect_type == TowerEffect.EffectType.APPLY_STATUS:
			return effect

	return null


static func _get_splash_radius_from_tier(tier_definition: Dictionary) -> float:
	var effect_definitions := tier_definition.get(EFFECTS_KEY, []) as Array
	if effect_definitions == null:
		return 0.0

	for candidate in effect_definitions:
		if _effect_type_from_value(_effect_value(candidate, EFFECT_TYPE_KEY, -1)) == TowerEffect.EffectType.SPLASH_DAMAGE:
			return float(_effect_value(candidate, EFFECT_RADIUS_KEY, 0.0))

	return 0.0


func _get_splash_radius_cells(effects: Array) -> float:
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


func _status_duration_from_effect(status_effect) -> float:
	if status_effect != null:
		return status_effect.duration
	return 0.0


func _status_move_speed_multiplier_from_effect(status_effect) -> float:
	if status_effect != null:
		return status_effect.move_speed_multiplier
	return 1.0


func _status_tick_interval_from_effect(status_effect) -> float:
	if status_effect != null:
		return status_effect.tick_interval
	return 0.0


func _status_tick_damage_from_effect(status_effect) -> float:
	if status_effect != null:
		return status_effect.tick_damage
	return 0.0


func _status_stack_policy_from_effect(status_effect) -> int:
	if status_effect != null:
		return status_effect.resolved_stack_policy()
	return -1


func _slow_multiplier_from_status(
	status_type: int,
	status_move_speed_multiplier: float
) -> float:
	return status_move_speed_multiplier if status_type == StatusEvent.StatusType.SLOW else 1.0


func _slow_duration_from_status(status_type: int, status_duration: float) -> float:
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
			EFFECT_DURATION_KEY:
				return effect.duration
			EFFECT_MOVE_SPEED_MULTIPLIER_KEY:
				return effect.move_speed_multiplier
			EFFECT_TICK_INTERVAL_KEY:
				return effect.tick_interval
			EFFECT_TICK_DAMAGE_KEY:
				return effect.tick_damage
			ATTACK_TYPE_KEY:
				return effect.attack_type
			DAMAGE_SCHOOL_KEY:
				return effect.damage_school
			STACK_POLICY_KEY:
				return effect.stack_policy
		return default_value

	var dictionary := effect_definition as Dictionary
	if dictionary == null:
		return default_value

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


static func _tower_type_from_definition_key(key, tower_definition: Dictionary) -> int:
	if tower_definition.has(TYPE_KEY):
		return _tower_type_from_value(tower_definition[TYPE_KEY])
	if key is int:
		return int(key)
	return _tower_type_from_value(key)


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


static func _tower_id_label(tower_id: String) -> String:
	if tower_id.is_empty():
		return "Tower"

	var words := []
	for part in tower_id.split("_", false):
		for subpart in part.split("-", false):
			if subpart.is_empty():
				continue
			words.append(subpart.substr(0, 1).to_upper() + subpart.substr(1).to_lower())
	return " ".join(words)


static func _default_weapon_type(tower_type: int) -> int:
	match tower_type:
		GameTower.Type.AREA:
			return DamageTypes.WeaponType.CANNON
		GameTower.Type.SLOW, GameTower.Type.FLAME:
			return DamageTypes.WeaponType.SPELL
		GameTower.Type.POISON:
			return DamageTypes.WeaponType.CROSSBOW

	return DamageTypes.WeaponType.CROSSBOW


static func _default_damage_school(tower_type: int) -> int:
	match tower_type:
		GameTower.Type.SLOW:
			return DamageTypes.DamageSchool.FROST
		GameTower.Type.FLAME:
			return DamageTypes.DamageSchool.FIRE
		GameTower.Type.POISON:
			return DamageTypes.DamageSchool.POISON

	return DamageTypes.DamageSchool.PHYSICAL


static func _default_attack_pattern(tower_type: int) -> int:
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
