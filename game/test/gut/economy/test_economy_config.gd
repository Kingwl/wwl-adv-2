extends GutTest


func test_default_economy_config_loads_json_values() -> void:
	var config := EconomyConfig.load_from_path(EconomyConfig.DEFAULT_ECONOMY_CONFIG_PATH)

	assert_not_null(config)
	assert_eq(config.initial_gold, 100)
	assert_eq(config.basic_tower_cost, 25)
	assert_eq(config.default_kill_reward, 5)
	assert_eq(config.wave_clear_reward, 20)
	assert_eq(config.tower_removal_refund_ratio, 0.5)


func test_economy_config_from_dictionary_uses_validated_values() -> void:
	var config := EconomyConfig.from_dictionary({
		"initial_gold": 140,
		"default_tower_build_cost": 30,
		"default_kill_reward": 7,
		"wave_clear_reward": 24,
		"tower_removal_refund_ratio": 0.4,
	})

	assert_eq(config.initial_gold, 140)
	assert_eq(config.basic_tower_cost, 30)
	assert_eq(config.default_kill_reward, 7)
	assert_eq(config.wave_clear_reward, 24)
	assert_eq(config.tower_removal_refund_ratio, 0.4)
