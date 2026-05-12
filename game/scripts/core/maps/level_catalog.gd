class_name LevelCatalog
extends RefCounted

const SELECTED_LEVEL_META_KEY := "wwl_selected_level_path"
const START_IN_LEVEL_SELECT_META_KEY := "wwl_start_in_level_select"
const LEVEL_PATHS := [
	"res://data/levels/level_001.json",
	"res://data/levels/level_002.json",
	"res://data/levels/level_003.json",
	"res://data/levels/level_004.json",
	"res://data/levels/level_005.json",
]


static func get_level_paths() -> Array:
	return LEVEL_PATHS.duplicate()


static func get_default_level_path() -> String:
	return String(LEVEL_PATHS[0])


static func get_level_summaries() -> Array:
	var summaries := []
	for index in range(LEVEL_PATHS.size()):
		var level_path := String(LEVEL_PATHS[index])
		var level := LevelDefinition.load_from_path(level_path)
		if level == null:
			continue

		summaries.append({
			"index": index,
			"path": level_path,
			"id": level.id,
			"display_name": level.display_name,
			"style_id": level.style_id,
			"wave_set_id": level.wave_set_id,
		})

	return summaries


static func get_level_display_name(level_path_or_id: String) -> String:
	var summary := get_level_summary(level_path_or_id)
	return String(summary.get("display_name", "")) if not summary.is_empty() else ""


static func get_level_summary(level_path_or_id: String) -> Dictionary:
	var target_index := get_level_index(level_path_or_id)
	if target_index < 0:
		return {}

	for summary in get_level_summaries():
		if int(summary.get("index", -1)) == target_index:
			return summary

	return {}


static func get_level_index(level_path_or_id: String) -> int:
	var normalized_target := _normalized_level_key(level_path_or_id)
	if normalized_target.is_empty():
		normalized_target = _normalized_level_key(get_default_level_path())

	for index in range(LEVEL_PATHS.size()):
		var level_path := String(LEVEL_PATHS[index])
		if _normalized_level_key(level_path) == normalized_target:
			return index

		var level := LevelDefinition.load_from_path(level_path)
		if level != null and _normalized_level_key(level.id) == normalized_target:
			return index

	return -1


static func get_next_level_path(level_path_or_id: String) -> String:
	var current_index := get_level_index(level_path_or_id)
	if current_index < 0 or current_index >= LEVEL_PATHS.size() - 1:
		return ""

	return String(LEVEL_PATHS[current_index + 1])


static func get_level_path_for_id(level_id: String) -> String:
	var level_index := get_level_index(level_id)
	if level_index < 0:
		return ""

	return String(LEVEL_PATHS[level_index])


static func _normalized_level_key(level_path_or_id: String) -> String:
	return level_path_or_id.strip_edges().to_lower()
