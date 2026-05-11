extends GutTest


func test_default_enemy_catalog_loads_json_enemy_definitions() -> void:
	var catalog := EnemyCatalog.new()
	var grunt := catalog.get_definition("grunt")
	var raider := catalog.get_definition("raider")

	assert_not_null(grunt)
	assert_eq(grunt.id, "grunt")
	assert_eq(grunt.max_health, 20.0)
	assert_eq(grunt.speed_cells_per_second, 1.0)
	assert_eq(grunt.kill_reward, 5)
	assert_eq(grunt.armor_type, DamageTypes.ArmorType.HEAVY)
	assert_eq(grunt.race_type, DamageTypes.RaceType.BEAST)
	assert_not_null(raider)
	assert_eq(raider.max_health, 30.0)
	assert_eq(raider.speed_cells_per_second, 1.1)
	assert_eq(raider.kill_reward, 6)


func test_enemy_definition_creates_enemy_with_affinity_fields() -> void:
	var definition := EnemyDefinition.from_dictionary({
		"id": "shade",
		"display_name": "Shade",
		"speed_cells_per_second": 1.25,
		"max_health": 18.0,
		"kill_reward": 8,
		"armor_type": "LIGHT",
		"race_type": "UNDEAD",
		"school_resistance_overrides": {
			"FIRE": -0.5,
			"POISON": 0.75,
		},
	})

	var enemy := definition.create_enemy("shade-1")

	assert_eq(enemy.id, "shade-1")
	assert_eq(enemy.speed_cells_per_second, 1.25)
	assert_eq(enemy.max_health, 18.0)
	assert_eq(enemy.kill_reward, 8)
	assert_eq(enemy.armor_type, DamageTypes.ArmorType.LIGHT)
	assert_eq(enemy.race_type, DamageTypes.RaceType.UNDEAD)
	assert_eq(enemy.school_resistance_overrides[DamageTypes.DamageSchool.FIRE], -0.5)
	assert_eq(enemy.school_resistance_overrides[DamageTypes.DamageSchool.POISON], 0.75)


func test_validate_definitions_rejects_duplicate_or_invalid_enemy_data() -> void:
	var errors := EnemyCatalog.validate_data({
		"enemies": [
			{
				"id": "bad",
				"display_name": "",
				"speed_cells_per_second": 0.0,
				"max_health": -1.0,
				"kill_reward": -1,
				"armor_type": "NOPE",
				"race_type": "BEAST",
			},
			{
				"id": "bad",
				"display_name": "Duplicate",
				"speed_cells_per_second": 1.0,
				"max_health": 1.0,
				"kill_reward": 0,
				"armor_type": "HEAVY",
				"race_type": "BEAST",
			},
		],
	})

	assert_has(errors, "bad display_name is required.")
	assert_has(errors, "bad speed_cells_per_second must be positive.")
	assert_has(errors, "bad max_health must be positive.")
	assert_has(errors, "bad kill_reward cannot be negative.")
	assert_has(errors, "bad armor_type is invalid.")
	assert_has(errors, "Duplicate enemy id: bad.")
