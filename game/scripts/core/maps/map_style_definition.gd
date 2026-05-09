class_name MapStyleDefinition
extends RefCounted

var id: String
var display_name: String
var tile_size: int
var background_tile_path: String
var background_normal_tile_path: String
var normal_light_enabled: bool
var normal_light_energy: float
var normal_light_height: float
var normal_light_rotation_degrees: float
var normal_light_color: Color
var blocked_tile_path: String
var locked_tile_path: String


static func load_from_path(resource_path: String) -> MapStyleDefinition:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load map style definition: %s" % resource_path)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Map style definition must be a JSON object: %s" % resource_path)
		return null

	return MapStyleDefinition.from_dictionary(parsed as Dictionary)


static func from_dictionary(data: Dictionary) -> MapStyleDefinition:
	var style := MapStyleDefinition.new()
	var tiles: Dictionary = data.get("tiles", {}) as Dictionary
	var lighting: Dictionary = data.get("lighting", {}) as Dictionary

	style.id = data.get("id", "")
	style.display_name = data.get("display_name", style.id)
	style.tile_size = int(data.get("tile_size", 128))
	style.background_tile_path = data.get("background", "")
	style.background_normal_tile_path = data.get("background_normal", "")
	style.normal_light_enabled = bool(lighting.get("normal_light_enabled", false))
	style.normal_light_energy = maxf(0.0, float(lighting.get("normal_light_energy", 0.8)))
	style.normal_light_height = maxf(0.0, float(lighting.get("normal_light_height", 0.35)))
	style.normal_light_rotation_degrees = float(lighting.get("normal_light_rotation_degrees", -45.0))
	style.normal_light_color = MapStyleDefinition._color_from_value(
		lighting.get("normal_light_color", [1.0, 0.96, 0.88, 1.0])
	)
	style.blocked_tile_path = tiles.get("blocked", "")
	style.locked_tile_path = tiles.get("locked", "")

	return style


func is_valid() -> bool:
	return not id.is_empty() and tile_size > 0 and not background_tile_path.is_empty()


func get_slot_tile_path(slot_type: BoardSlot.Type) -> String:
	match slot_type:
		BoardSlot.Type.BLOCKED:
			return blocked_tile_path
		BoardSlot.Type.LOCKED:
			return locked_tile_path

	return ""


func get_all_tile_paths() -> Array:
	var paths := []
	if not background_tile_path.is_empty():
		paths.append(background_tile_path)
	if not background_normal_tile_path.is_empty():
		paths.append(background_normal_tile_path)

	if not blocked_tile_path.is_empty():
		paths.append(blocked_tile_path)
	if not locked_tile_path.is_empty():
		paths.append(locked_tile_path)

	return paths


static func _color_from_value(value) -> Color:
	if value is Color:
		return value

	if value is Array and value.size() >= 3:
		var alpha := 1.0
		if value.size() >= 4:
			alpha = float(value[3])
		return Color(float(value[0]), float(value[1]), float(value[2]), alpha)

	return Color(1.0, 0.96, 0.88, 1.0)
