class_name TowerPresentationCatalog
extends RefCounted

var tower_config: TowerConfig


func _init(new_tower_config: TowerConfig = null) -> void:
	tower_config = new_tower_config
	if tower_config == null:
		tower_config = TowerConfig.new()


func get_tower_button_node_name(tower_id: String) -> String:
	return "%sTowerButton" % _pascal_case_id(tower_id)


func get_tower_button_specs() -> Array:
	var specs := []
	for candidate_id in tower_config.get_tower_ids():
		var tower_id := String(candidate_id)
		var tower_type := tower_config.get_tower_type_for_id(tower_id)
		var node_name := get_tower_button_node_name(tower_id)
		specs.append({
			"name": tower_id,
			"tower_id": tower_id,
			"tower_type": tower_type,
			"display_name": tower_config.get_display_name_for_id(tower_id),
			"description": tower_config.get_description_for_id(tower_id),
			"build_cost": tower_config.get_build_cost_for_id(tower_id),
			"node_name": node_name,
			"node_path": "Hud/%s" % node_name,
		})

	return specs


func get_visual_test_tower_specs() -> Array:
	var specs := []
	for candidate_id in tower_config.get_tower_ids():
		var tower_id := String(candidate_id)
		if tower_config.is_visual_test_enabled_for_id(tower_id):
			specs.append({
				"name": tower_id,
				"tower_id": tower_id,
				"tower_type": tower_config.get_tower_type_for_id(tower_id),
				"display_name": tower_config.get_display_name_for_id(tower_id),
			})

	return specs


static func _pascal_case_id(value: String) -> String:
	var result := ""
	for part in value.split("_", false):
		for subpart in part.split("-", false):
			if subpart.is_empty():
				continue
			result += subpart.substr(0, 1).to_upper() + subpart.substr(1).to_lower()
	return result
