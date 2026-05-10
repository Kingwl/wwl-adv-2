class_name DamageAffinityConfig
extends RefCounted

const ATTACK_VS_ARMOR := {
	DamageTypes.AttackType.NORMAL: {
		DamageTypes.ArmorType.UNARMORED: 1.0,
		DamageTypes.ArmorType.LIGHT: 1.0,
		DamageTypes.ArmorType.MEDIUM: 1.5,
		DamageTypes.ArmorType.HEAVY: 1.0,
		DamageTypes.ArmorType.FORTIFIED: 0.7,
		DamageTypes.ArmorType.HERO: 1.0,
	},
	DamageTypes.AttackType.PIERCE: {
		DamageTypes.ArmorType.UNARMORED: 1.5,
		DamageTypes.ArmorType.LIGHT: 2.0,
		DamageTypes.ArmorType.MEDIUM: 0.75,
		DamageTypes.ArmorType.HEAVY: 1.0,
		DamageTypes.ArmorType.FORTIFIED: 0.35,
		DamageTypes.ArmorType.HERO: 0.5,
	},
	DamageTypes.AttackType.SIEGE: {
		DamageTypes.ArmorType.UNARMORED: 1.5,
		DamageTypes.ArmorType.LIGHT: 0.5,
		DamageTypes.ArmorType.MEDIUM: 0.5,
		DamageTypes.ArmorType.HEAVY: 1.0,
		DamageTypes.ArmorType.FORTIFIED: 1.5,
		DamageTypes.ArmorType.HERO: 0.5,
	},
	DamageTypes.AttackType.MAGIC: {
		DamageTypes.ArmorType.UNARMORED: 1.0,
		DamageTypes.ArmorType.LIGHT: 1.25,
		DamageTypes.ArmorType.MEDIUM: 0.75,
		DamageTypes.ArmorType.HEAVY: 2.0,
		DamageTypes.ArmorType.FORTIFIED: 0.35,
		DamageTypes.ArmorType.HERO: 0.5,
	},
	DamageTypes.AttackType.HERO: {
		DamageTypes.ArmorType.UNARMORED: 1.0,
		DamageTypes.ArmorType.LIGHT: 1.0,
		DamageTypes.ArmorType.MEDIUM: 1.0,
		DamageTypes.ArmorType.HEAVY: 1.0,
		DamageTypes.ArmorType.FORTIFIED: 0.5,
		DamageTypes.ArmorType.HERO: 1.0,
	},
	DamageTypes.AttackType.CHAOS: {
		DamageTypes.ArmorType.UNARMORED: 1.0,
		DamageTypes.ArmorType.LIGHT: 1.0,
		DamageTypes.ArmorType.MEDIUM: 1.0,
		DamageTypes.ArmorType.HEAVY: 1.0,
		DamageTypes.ArmorType.FORTIFIED: 1.0,
		DamageTypes.ArmorType.HERO: 1.0,
	},
}

const RACE_SCHOOL_RESISTANCE := {
	DamageTypes.RaceType.BEAST: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: 0.0,
		DamageTypes.DamageSchool.POISON: 0.0,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.HUMANOID: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: 0.0,
		DamageTypes.DamageSchool.POISON: 0.0,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.UNDEAD: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: -0.25,
		DamageTypes.DamageSchool.POISON: 0.5,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: -0.25,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.CONSTRUCT: {
		DamageTypes.DamageSchool.PHYSICAL: 0.1,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: 0.0,
		DamageTypes.DamageSchool.POISON: 0.75,
		DamageTypes.DamageSchool.LIGHTNING: -0.5,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.ELEMENTAL_FIRE: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: -0.5,
		DamageTypes.DamageSchool.FIRE: 0.5,
		DamageTypes.DamageSchool.POISON: 0.25,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.ELEMENTAL_FROST: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.5,
		DamageTypes.DamageSchool.FIRE: -0.5,
		DamageTypes.DamageSchool.POISON: 0.25,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.PLANT: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: -0.5,
		DamageTypes.DamageSchool.POISON: 0.5,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: 0.0,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
	DamageTypes.RaceType.DEMON: {
		DamageTypes.DamageSchool.PHYSICAL: 0.0,
		DamageTypes.DamageSchool.FROST: 0.0,
		DamageTypes.DamageSchool.FIRE: 0.25,
		DamageTypes.DamageSchool.POISON: 0.25,
		DamageTypes.DamageSchool.LIGHTNING: 0.0,
		DamageTypes.DamageSchool.ARCANE: -0.25,
		DamageTypes.DamageSchool.SHADOW: 0.0,
	},
}


func get_attack_type_for_weapon(weapon_type: int) -> int:
	match weapon_type:
		DamageTypes.WeaponType.BOW, DamageTypes.WeaponType.CROSSBOW:
			return DamageTypes.AttackType.PIERCE
		DamageTypes.WeaponType.CANNON:
			return DamageTypes.AttackType.SIEGE
		DamageTypes.WeaponType.BLADE:
			return DamageTypes.AttackType.NORMAL
		DamageTypes.WeaponType.SPELL:
			return DamageTypes.AttackType.MAGIC
		DamageTypes.WeaponType.HEROIC:
			return DamageTypes.AttackType.HERO
		DamageTypes.WeaponType.CHAOS:
			return DamageTypes.AttackType.CHAOS

	return DamageTypes.AttackType.NORMAL


func get_attack_vs_armor_multiplier(attack_type: int, armor_type: int) -> float:
	var armor_table := ATTACK_VS_ARMOR.get(attack_type, {}) as Dictionary
	return float(armor_table.get(armor_type, 1.0))


func get_race_school_resistance(
	race_type: int,
	damage_school: int,
	school_resistance_overrides: Dictionary = {}
) -> float:
	if school_resistance_overrides.has(damage_school):
		return float(school_resistance_overrides[damage_school])

	var race_table := RACE_SCHOOL_RESISTANCE.get(race_type, {}) as Dictionary
	return float(race_table.get(damage_school, 0.0))


func calculate_final_damage(
	base_damage: float,
	attack_type: int,
	armor_type: int,
	damage_school: int,
	race_type: int,
	other_modifiers: float = 1.0,
	school_resistance_overrides: Dictionary = {}
) -> float:
	assert(base_damage >= 0.0, "Base damage cannot be negative.")
	assert(other_modifiers >= 0.0, "Damage modifiers cannot be negative.")

	var attack_multiplier := get_attack_vs_armor_multiplier(attack_type, armor_type)
	var resistance := get_race_school_resistance(race_type, damage_school, school_resistance_overrides)
	var school_multiplier := 1.0 - resistance
	return maxf(0.0, base_damage * attack_multiplier * school_multiplier * other_modifiers)
