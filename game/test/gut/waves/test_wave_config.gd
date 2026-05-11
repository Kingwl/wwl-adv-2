extends GutTest


func test_default_wave_config_loads_json_waves_and_enemy_refs() -> void:
	var enemy_catalog := EnemyCatalog.new()
	var wave_definitions := WaveConfig.load_definitions_from_path(
		WaveConfig.DEFAULT_WAVE_DEFINITION_PATH,
		enemy_catalog
	)

	assert_eq(wave_definitions.size(), 8)
	assert_eq(wave_definitions[0].wave_id, "wave-1")
	assert_eq(wave_definitions[0].enemy_type_id, "grunt")
	assert_eq(wave_definitions[0].enemy_count, 4)
	assert_eq(wave_definitions[0].spawn_interval_seconds, 0.95)
	assert_eq(wave_definitions[0].enemy_max_health, 20.0)
	assert_eq(wave_definitions[0].enemy_speed_cells_per_second, 1.0)
	assert_eq(wave_definitions[0].enemy_kill_reward, 5)
	assert_eq(wave_definitions[7].wave_id, "wave-8")
	assert_eq(wave_definitions[7].enemy_type_id, "raider")
	assert_eq(wave_definitions[7].enemy_count, 7)
	assert_eq(wave_definitions[7].enemy_max_health, 30.0)
	assert_eq(wave_definitions[7].enemy_speed_cells_per_second, 1.1)
	assert_eq(wave_definitions[7].enemy_kill_reward, 6)


func test_wave_config_loads_level_specific_wave_set() -> void:
	var level := LevelDefinition.load_from_path("res://data/levels/level_005.json")
	var wave_definitions := WaveConfig.load_definitions_for_level(level, EnemyCatalog.new())

	assert_eq(level.wave_set_id, "level_005_mvp_showcase")
	assert_eq(wave_definitions.size(), 8)
	assert_eq(wave_definitions[0].enemy_type_id, "grunt")
	assert_eq(wave_definitions[0].enemy_count, 8)
	assert_eq(wave_definitions[7].enemy_type_id, "raider")
	assert_eq(wave_definitions[7].enemy_count, 16)
	assert_eq(wave_definitions[7].spawn_interval_seconds, 0.45)
	assert_eq(wave_definitions[7].clear_reward_gold, 80)


func test_wave_config_resolves_wave_set_id_to_data_path() -> void:
	assert_eq(
		WaveConfig.wave_set_path("level_003_kill_zone"),
		"res://data/waves/level_003_kill_zone.json"
	)
	assert_eq(WaveConfig.wave_set_path(""), WaveConfig.DEFAULT_WAVE_DEFINITION_PATH)


func test_wave_config_validation_rejects_unknown_enemy_type() -> void:
	var errors := WaveConfig.validate_data(
		{
			"waves": [
				{
					"id": "wave-x",
					"enemy_type": "missing",
					"enemy_count": 1,
					"spawn_interval_seconds": 1.0,
					"clear_reward_gold": 0,
				},
			],
		},
		EnemyCatalog.new({
			"grunt": EnemyDefinition.from_dictionary({
				"id": "grunt",
				"display_name": "Grunt",
				"speed_cells_per_second": 1.0,
				"max_health": 20.0,
				"kill_reward": 5,
				"armor_type": "HEAVY",
				"race_type": "BEAST",
			}),
		})
	)

	assert_has(errors, "wave-x enemy_type is unknown: missing.")
