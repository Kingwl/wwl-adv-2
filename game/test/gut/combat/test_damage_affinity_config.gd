extends GutTest


func test_weapon_type_defaults_to_attack_type() -> void:
	var config := DamageAffinityConfig.new()

	assert_eq(config.get_attack_type_for_weapon(DamageTypes.WeaponType.CROSSBOW), DamageTypes.AttackType.PIERCE)
	assert_eq(config.get_attack_type_for_weapon(DamageTypes.WeaponType.CANNON), DamageTypes.AttackType.SIEGE)
	assert_eq(config.get_attack_type_for_weapon(DamageTypes.WeaponType.SPELL), DamageTypes.AttackType.MAGIC)


func test_attack_type_vs_armor_multiplier_table() -> void:
	var config := DamageAffinityConfig.new()

	assert_eq(config.get_attack_vs_armor_multiplier(DamageTypes.AttackType.PIERCE, DamageTypes.ArmorType.LIGHT), 2.0)
	assert_eq(config.get_attack_vs_armor_multiplier(DamageTypes.AttackType.MAGIC, DamageTypes.ArmorType.HEAVY), 2.0)
	assert_eq(config.get_attack_vs_armor_multiplier(DamageTypes.AttackType.SIEGE, DamageTypes.ArmorType.FORTIFIED), 1.5)
	assert_eq(config.get_attack_vs_armor_multiplier(DamageTypes.AttackType.CHAOS, DamageTypes.ArmorType.HERO), 1.0)


func test_race_school_resistance_supports_positive_and_negative_values() -> void:
	var config := DamageAffinityConfig.new()

	assert_eq(config.get_race_school_resistance(DamageTypes.RaceType.UNDEAD, DamageTypes.DamageSchool.POISON), 0.5)
	assert_eq(config.get_race_school_resistance(DamageTypes.RaceType.UNDEAD, DamageTypes.DamageSchool.FIRE), -0.25)
	assert_eq(config.get_race_school_resistance(DamageTypes.RaceType.CONSTRUCT, DamageTypes.DamageSchool.LIGHTNING), -0.5)


func test_calculate_final_damage_combines_attack_armor_and_race_resistance() -> void:
	var config := DamageAffinityConfig.new()

	assert_eq(config.calculate_final_damage(
		10.0,
		DamageTypes.AttackType.MAGIC,
		DamageTypes.ArmorType.HEAVY,
		DamageTypes.DamageSchool.FIRE,
		DamageTypes.RaceType.UNDEAD
	), 25.0)


func test_resistance_overrides_can_make_specific_enemy_weaker() -> void:
	var config := DamageAffinityConfig.new()

	assert_eq(config.calculate_final_damage(
		10.0,
		DamageTypes.AttackType.MAGIC,
		DamageTypes.ArmorType.HEAVY,
		DamageTypes.DamageSchool.FIRE,
		DamageTypes.RaceType.UNDEAD,
		1.0,
		{DamageTypes.DamageSchool.FIRE: -0.5}
	), 30.0)
