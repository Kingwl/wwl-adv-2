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
	for tower_type in tower_config.get_tower_types():
		var tower_id := tower_config.get_tower_id(tower_type)
		var node_name := get_tower_button_node_name(tower_id)
		specs.append({
			"name": tower_id,
			"tower_id": tower_id,
			"tower_type": tower_type,
			"display_name": tower_config.get_display_name(tower_type),
			"description": tower_config.get_description(tower_type),
			"build_cost": tower_config.get_build_cost(tower_type),
			"node_name": node_name,
			"node_path": "Hud/%s" % node_name,
		})

	return specs


func get_visual_test_tower_specs() -> Array:
	var specs := []
	for tower_type in tower_config.get_tower_types():
		if tower_config.is_visual_test_enabled(tower_type):
			var tower_id := tower_config.get_tower_id(tower_type)
			specs.append({
				"name": tower_id,
				"tower_id": tower_id,
				"tower_type": tower_type,
				"display_name": tower_config.get_display_name(tower_type),
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
