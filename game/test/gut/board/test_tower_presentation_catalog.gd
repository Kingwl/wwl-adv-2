extends GutTest


func test_button_specs_are_built_from_tower_config_roster() -> void:
	var catalog := TowerPresentationCatalog.new(TowerConfig.new())

	var specs := catalog.get_tower_button_specs()
	var poison_spec := specs[4] as Dictionary

	assert_eq(specs.size(), 5)
	assert_eq(poison_spec["name"], "poison")
	assert_eq(poison_spec["tower_id"], "poison")
	assert_eq(poison_spec["tower_type"], GameTower.Type.POISON)
	assert_eq(poison_spec["display_name"], "Poison")
	assert_eq(poison_spec["description"], "Toxic DoT")
	assert_eq(poison_spec["build_cost"], 25)
	assert_eq(poison_spec["node_name"], "PoisonTowerButton")
	assert_eq(poison_spec["node_path"], "Hud/PoisonTowerButton")


func test_button_specs_can_include_non_enum_tower_ids() -> void:
	var catalog := TowerPresentationCatalog.new(TowerConfig.new({
		"storm": {
			"id": "storm",
			"type": "LIGHTNING",
			"display_name": "Storm",
			"description": "Chain lightning",
			"build_cost": 44,
			"tiers": [
				{
					"damage": 9.0,
					"range_cells": 2.8,
					"attack_interval": 1.3,
					"effects": [
						{
							"type": TowerEffect.EffectType.DAMAGE_PRIMARY,
						},
					],
				},
			],
		},
	}))

	var spec := catalog.get_tower_button_specs()[0] as Dictionary

	assert_eq(spec["tower_id"], "storm")
	assert_eq(spec["tower_type"], -1)
	assert_eq(spec["display_name"], "Storm")
	assert_eq(spec["build_cost"], 44)
	assert_eq(spec["node_name"], "StormTowerButton")


func test_visual_specs_follow_visual_test_flag() -> void:
	var definitions := TowerConfig.load_definitions_from_path(TowerConfig.DEFAULT_TOWER_DEFINITION_PATH)
	var slow_definition := definitions["slow"] as Dictionary
	slow_definition[TowerConfig.VISUAL_TEST_ENABLED_KEY] = false
	var catalog := TowerPresentationCatalog.new(TowerConfig.new(definitions))

	var specs := catalog.get_visual_test_tower_specs()

	assert_eq(specs.size(), 4)
	assert_false(_spec_ids(specs).has("slow"))
	assert_true(_spec_ids(specs).has("poison"))


func _spec_ids(specs: Array) -> Array:
	var ids := []
	for spec in specs:
		ids.append(String((spec as Dictionary)["tower_id"]))
	return ids
