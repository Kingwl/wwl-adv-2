extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const LEVEL_DIR := "res://data/levels"
const DEFAULT_ARTIFACT_DIR := "res://../ci-artifacts/level-grid-audit/native"
const DEFAULT_VIEWPORT_SIZE := Vector2i(1280, 720)
const MIN_NON_DARK_RATIO := 0.05
const MIN_LUMINANCE_RANGE := 0.05
const CROP_SCALE := 2
const BOARD_CROP_MARGIN := 24.0
const OVERLAY_BOARD_COLOR := Color(0.10, 0.70, 1.0, 1.0)
const OVERLAY_BUILDABLE_COLOR := Color(0.20, 1.0, 0.35, 1.0)
const OVERLAY_PATH_COLOR := Color(1.0, 0.15, 0.80, 1.0)
const OVERLAY_BLOCKED_COLOR := Color(1.0, 0.78, 0.12, 1.0)
const OVERLAY_TOWER_COLOR := Color(0.20, 1.0, 0.35, 1.0)
const OVERLAY_ENEMY_COLOR := Color(1.0, 0.15, 0.80, 1.0)

var _artifact_dir := ""
var _report := {}
var _failed := false
var _viewport_size := DEFAULT_VIEWPORT_SIZE
var _active_scene: Node


func _initialize() -> void:
	_artifact_dir = _resolve_artifact_dir()
	DirAccess.make_dir_recursive_absolute(_artifact_dir)
	_viewport_size = _parse_viewport()
	_report = {
		"ok": true,
		"started_at_unix": Time.get_unix_time_from_system(),
		"viewport": {"width": _viewport_size.x, "height": _viewport_size.y},
		"levels": [],
		"failures": [],
	}
	call_deferred("_run")


func _run() -> void:
	print("Level grid audit artifacts: %s" % _artifact_dir)
	_set_viewport_size(_viewport_size)
	await _settle_frames(4)

	for level_path in _parse_levels():
		var result := await _run_level(level_path)
		_report["levels"].append(result)
		if not result["ok"]:
			_failed = true

	if _active_scene != null:
		_active_scene.queue_free()
		_active_scene = null
		await process_frame

	_report["ok"] = not _failed
	_report["finished_at_unix"] = Time.get_unix_time_from_system()
	_write_reports()
	quit(1 if _failed else 0)


func _parse_levels() -> Array:
	var override := OS.get_environment("LEVEL_GRID_AUDIT_LEVELS")
	if not override.is_empty():
		var levels := []
		for raw_entry in override.split(",", false):
			var level_path := raw_entry.strip_edges()
			if not level_path.is_empty():
				levels.append(level_path)
		return levels

	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		return []

	var files := []
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.ends_with(".json"):
			files.append(file_name)
	dir.list_dir_end()
	files.sort()

	var level_paths := []
	for file_name in files:
		level_paths.append("%s/%s" % [LEVEL_DIR, file_name])
	return level_paths


func _parse_viewport() -> Vector2i:
	var override := OS.get_environment("LEVEL_GRID_AUDIT_VIEWPORT")
	if override.is_empty():
		return DEFAULT_VIEWPORT_SIZE

	var parts := override.strip_edges().split("x", false)
	if parts.size() != 2:
		return DEFAULT_VIEWPORT_SIZE
	var width := int(parts[0])
	var height := int(parts[1])
	if width <= 0 or height <= 0:
		return DEFAULT_VIEWPORT_SIZE
	return Vector2i(width, height)


func _run_level(level_path: String) -> Dictionary:
	var level := LevelDefinition.load_from_path(level_path)
	var result := {
		"level_path": level_path,
		"level_id": "",
		"display_name": "",
		"style_id": "",
		"ok": true,
		"checks": [],
		"failures": [],
		"summary": {},
		"artifacts": [],
	}

	_check(result, level != null, "level loads", {"level_path": level_path})
	if level == null:
		return _finalize_level(result)

	result["level_id"] = level.id
	result["display_name"] = level.display_name
	result["style_id"] = level.style_id
	var level_dir := _artifact_dir.path_join(level.id)
	DirAccess.make_dir_recursive_absolute(level_dir)

	var counts := _audit_placement_rules(result, level)
	var path_summary := _audit_path_following(result, level)
	result["summary"] = {
		"grid_width": level.grid_width,
		"grid_height": level.grid_height,
		"buildable_cells": counts["buildable_cells"],
		"path_cells": counts["path_cells"],
		"blocked_cells": counts["blocked_cells"],
		"locked_cells": counts["locked_cells"],
		"placement_attempts": counts["placement_attempts"],
		"expected_successes": counts["expected_successes"],
		"path_steps": path_summary["path_steps"],
		"path_distance": path_summary["path_distance"],
	}

	var build_scene := await _instantiate_main_scene(result, level_path, level.id)
	if build_scene != null:
		var board_view := build_scene.get_node_or_null("BoardView") as BoardView
		_prepare_static_scene(board_view)
		_populate_all_buildable_towers(result, board_view, int(counts["buildable_cells"]))
		await _capture_board_artifact(result, level_dir, level.id, "buildable-grid", board_view)
		await _unload_active_scene()

	var path_scene := await _instantiate_main_scene(result, level_path, level.id)
	if path_scene != null:
		var board_view := path_scene.get_node_or_null("BoardView") as BoardView
		_prepare_static_scene(board_view)
		_populate_path_enemies(result, board_view, level)
		await _capture_board_artifact(result, level_dir, level.id, "path-enemies", board_view)
		await _unload_active_scene()

	return _finalize_level(result)


func _audit_placement_rules(result: Dictionary, level: LevelDefinition) -> Dictionary:
	var board := Board.new(level.grid_width, level.grid_height)
	level.apply_to_board(board)
	var path_result := board.validate_path(level.path_cells)
	_check(result, path_result.succeeded, "level path validates", {"level_id": level.id})

	var counts := {
		"buildable_cells": 0,
		"path_cells": 0,
		"blocked_cells": 0,
		"locked_cells": 0,
		"placement_attempts": 0,
		"expected_successes": 0,
	}

	for y in range(level.grid_height):
		for x in range(level.grid_width):
			var position := Vector2i(x, y)
			var slot_type := board.get_slot_type(position)
			match slot_type:
				BoardSlot.Type.BUILDABLE:
					counts["buildable_cells"] = int(counts["buildable_cells"]) + 1
				BoardSlot.Type.PATH:
					counts["path_cells"] = int(counts["path_cells"]) + 1
				BoardSlot.Type.BLOCKED:
					counts["blocked_cells"] = int(counts["blocked_cells"]) + 1
				BoardSlot.Type.LOCKED:
					counts["locked_cells"] = int(counts["locked_cells"]) + 1

			var expected_buildable := slot_type == BoardSlot.Type.BUILDABLE
			var session := BoardGameSession.new()
			session.level_definition = level
			session.initialize_board()
			session.initialize_combat()
			session.select_tower_id("single")
			var placement := session.try_place_at_grid(position)
			counts["placement_attempts"] = int(counts["placement_attempts"]) + 1
			if expected_buildable:
				counts["expected_successes"] = int(counts["expected_successes"]) + 1
			_check(
				result,
				placement.succeeded == expected_buildable,
				"cell placement matches slot type",
				{
					"level_id": level.id,
					"cell": [position.x, position.y],
					"slot_type": _slot_type_name(slot_type),
					"expected_buildable": expected_buildable,
					"actual_succeeded": placement.succeeded,
				}
			)

	return counts


func _audit_path_following(result: Dictionary, level: LevelDefinition) -> Dictionary:
	var follower := PathFollower.new(level.path_cells)
	var moving_enemy := Enemy.new("%s-core-path-enemy" % level.id, 1.0)
	for index in range(1, level.path_cells.size()):
		follower.advance(moving_enemy, 1.0)
		var expected_cell: Vector2i = level.path_cells[index]
		var actual_cell := follower.get_grid_position(moving_enemy)
		_check(
			result,
			actual_cell == expected_cell,
			"path follower reaches expected cell",
			{
				"level_id": level.id,
				"path_index": index,
				"expected": [expected_cell.x, expected_cell.y],
				"actual": [actual_cell.x, actual_cell.y],
			}
		)

	_check(result, moving_enemy.completed, "path follower completes path", {"level_id": level.id})
	return {
		"path_steps": level.path_cells.size(),
		"path_distance": follower.total_distance,
	}


func _instantiate_main_scene(result: Dictionary, level_path: String, level_id: String) -> Node:
	await _unload_active_scene()
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_check(result, packed != null, "main scene loads", {"level_id": level_id})
	if packed == null:
		return null

	var scene := packed.instantiate()
	var board_view := scene.get_node_or_null("BoardView") as BoardView
	_check(result, board_view != null, "board view exists", {"level_id": level_id})
	if board_view == null:
		scene.queue_free()
		return null

	board_view.level_definition_path = level_path
	get_root().add_child(scene)
	current_scene = scene
	_active_scene = scene
	await _settle_frames(8)
	board_view = scene.get_node_or_null("BoardView") as BoardView
	_check(result, board_view != null, "board view ready", {"level_id": level_id})
	if board_view == null:
		return scene

	_check(result, board_view.get_asset_catalog().level_definition.id == level_id, "board view uses requested level")
	_check(result, board_view.get_session().board.width == board_view.get_asset_catalog().level_definition.grid_width, "runtime board width matches level")
	_check(result, board_view.get_session().board.height == board_view.get_asset_catalog().level_definition.grid_height, "runtime board height matches level")
	return scene


func _prepare_static_scene(board_view: BoardView) -> void:
	if board_view == null:
		return
	board_view.set_process(false)
	board_view.apply_responsive_layout(Vector2(_viewport_size))
	board_view.start_game()
	board_view.get_session().combat_simulation.wave_spawner = null
	board_view.get_session().combat_simulation.enemies = []
	board_view.get_session().combat_simulation.projectiles = []
	board_view.get_visual_state().attack_feedbacks = []
	board_view.get_visual_state().enemy_death_animations = []
	board_view.refresh_hud()
	board_view.queue_redraw()


func _populate_all_buildable_towers(result: Dictionary, board_view: BoardView, expected_count: int) -> void:
	if board_view == null:
		return
	board_view.get_session().wallet.earn(100000, TransactionRecord.Reason.DEBUG, "level-grid-audit")
	board_view.select_tower_id("single")

	for y in range(board_view.get_session().board.height):
		for x in range(board_view.get_session().board.width):
			var position := Vector2i(x, y)
			if board_view.get_session().board.get_slot_type(position) != BoardSlot.Type.BUILDABLE:
				continue
			var placement := board_view.try_place_at_grid(position)
			_check(
				result,
				placement.succeeded,
				"runtime buildable cell placement succeeds",
				{"level_id": board_view.get_asset_catalog().level_definition.id, "cell": [x, y]}
			)

	var tower_count := board_view.get_session().placement_service.tower_registry.get_all_towers().size()
	_check(
		result,
		tower_count == expected_count,
		"runtime tower count matches buildable cells",
		{
			"level_id": board_view.get_asset_catalog().level_definition.id,
			"expected": expected_count,
			"actual": tower_count,
		}
	)
	board_view.get_session().last_placement_result = null
	board_view.hover_grid_position = BoardView.INVALID_GRID_POSITION
	board_view.clear_tower_action_menu()
	board_view.refresh_hud()
	board_view.queue_redraw()


func _populate_path_enemies(result: Dictionary, board_view: BoardView, level: LevelDefinition) -> void:
	if board_view == null:
		return

	var enemies := []
	var total_distance := maxf(0.0, float(level.path_cells.size() - 1))
	for index in range(level.path_cells.size()):
		var enemy := Enemy.new("%s-path-enemy-%02d" % [level.id, index], 1.0)
		enemy.path_distance = minf(float(index), total_distance)
		enemy.health = enemy.max_health
		enemy.completed = false
		enemies.append(enemy)

	board_view.get_session().combat_simulation.enemies = enemies
	board_view.refresh_hud()
	board_view.queue_redraw()
	_check(
		result,
		board_view.get_session().get_visible_enemies().size() == level.path_cells.size(),
		"runtime path enemy markers are visible",
		{
			"level_id": level.id,
			"expected": level.path_cells.size(),
			"actual": board_view.get_session().get_visible_enemies().size(),
		}
	)


func _capture_board_artifact(
	result: Dictionary,
	level_dir: String,
	level_id: String,
	checkpoint_name: String,
	board_view: BoardView
) -> void:
	if board_view == null:
		return

	board_view.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	_check(result, image != null, "capture %s screenshot" % checkpoint_name, {"level_id": level_id})
	if image == null:
		return

	var base_name := "%s-%s" % [level_id, checkpoint_name]
	var screenshot_path := level_dir.path_join("%s.png" % base_name)
	var save_error := image.save_png(screenshot_path)
	_check(result, save_error == OK, "save %s screenshot" % checkpoint_name, {"level_id": level_id})

	var board_rect := _board_global_rect(board_view)
	var crop_source_rect := board_rect.grow(BOARD_CROP_MARGIN)
	crop_source_rect.position.y = board_rect.position.y
	crop_source_rect.size.y = board_rect.size.y + BOARD_CROP_MARGIN
	var crop_rect := _image_crop_rect(crop_source_rect, Vector2i(image.get_width(), image.get_height()))
	var board_crop := image.get_region(crop_rect)
	var board_overlay := board_crop.duplicate()
	board_overlay.convert(Image.FORMAT_RGBA8)
	_draw_audit_overlay(board_overlay, Vector2(crop_rect.position), board_view)

	var scaled_crop := _scaled_image(board_crop)
	var scaled_overlay := _scaled_image(board_overlay)
	var board_crop_path := level_dir.path_join("%s-board.png" % base_name)
	var board_overlay_path := level_dir.path_join("%s-overlay.png" % base_name)
	var crop_error := scaled_crop.save_png(board_crop_path)
	var overlay_error := scaled_overlay.save_png(board_overlay_path)
	_check(result, crop_error == OK, "save %s board crop" % checkpoint_name, {"level_id": level_id})
	_check(result, overlay_error == OK, "save %s board overlay" % checkpoint_name, {"level_id": level_id})

	var stats := _image_stats(image)
	_check(result, stats["non_dark_ratio"] >= MIN_NON_DARK_RATIO, "screenshot is not blank", {"level_id": level_id, "checkpoint": checkpoint_name})
	_check(result, stats["luminance_range"] >= MIN_LUMINANCE_RANGE, "screenshot has contrast", {"level_id": level_id, "checkpoint": checkpoint_name})

	result["artifacts"].append({
		"name": checkpoint_name,
		"screenshot": screenshot_path,
		"board_crop": board_crop_path,
		"board_overlay": board_overlay_path,
		"stats": stats,
	})


func _draw_audit_overlay(image: Image, crop_origin: Vector2, board_view: BoardView) -> void:
	var board_rect := _board_global_rect(board_view)
	_draw_rect_outline(image, Rect2(board_rect.position - crop_origin, board_rect.size), OVERLAY_BOARD_COLOR, 2)

	var board := board_view.get_session().board
	for y in range(board.height):
		for x in range(board.width):
			var position := Vector2i(x, y)
			var local_rect := board_view.grid_to_local_rect(position)
			var global_rect := Rect2(board_view.to_global(local_rect.position), local_rect.size)
			var color := _slot_overlay_color(board.get_slot_type(position))
			_draw_rect_outline(image, Rect2(global_rect.position - crop_origin, global_rect.size), color, 1)

	for candidate in board_view.get_session().placement_service.tower_registry.get_all_towers():
		var tower := candidate as GameTower
		if tower == null:
			continue
		var tower_rect := board_view.grid_to_local_rect(tower.grid_position)
		var global_tower_rect := Rect2(board_view.to_global(tower_rect.position), tower_rect.size)
		_draw_rect_outline(image, Rect2(global_tower_rect.position - crop_origin, global_tower_rect.size), OVERLAY_TOWER_COLOR, 3)
		_draw_cross(image, global_tower_rect.get_center() - crop_origin, OVERLAY_TOWER_COLOR, 7)

	for candidate in board_view.get_session().combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.defeated:
			continue
		var enemy_position := board_view.to_global(_grid_space_to_local(board_view, board_view.get_session().path_follower.get_grid_space_position(enemy)))
		_draw_cross(image, enemy_position - crop_origin, OVERLAY_ENEMY_COLOR, 8)


func _slot_overlay_color(slot_type: int) -> Color:
	match slot_type:
		BoardSlot.Type.PATH:
			return OVERLAY_PATH_COLOR
		BoardSlot.Type.BLOCKED, BoardSlot.Type.LOCKED:
			return OVERLAY_BLOCKED_COLOR
		_:
			return OVERLAY_BUILDABLE_COLOR


func _slot_type_name(slot_type: int) -> String:
	match slot_type:
		BoardSlot.Type.PATH:
			return "PATH"
		BoardSlot.Type.BLOCKED:
			return "BLOCKED"
		BoardSlot.Type.LOCKED:
			return "LOCKED"
		_:
			return "BUILDABLE"


func _board_global_rect(board_view: BoardView) -> Rect2:
	return Rect2(
		board_view.to_global(board_view.get_layout_metrics().board_origin),
		Vector2(float(board_view.get_session().board.width) * board_view.get_layout_metrics().cell_size, float(board_view.get_session().board.height) * board_view.get_layout_metrics().cell_size)
	)


func _grid_space_to_local(board_view: BoardView, grid_space_position: Vector2) -> Vector2:
	return board_view.get_renderer().grid_space_to_local(
		board_view.get_layout_metrics().board_origin,
		board_view.get_layout_metrics().cell_size,
		grid_space_position
	)


func _unload_active_scene() -> void:
	if _active_scene == null:
		return
	_active_scene.queue_free()
	if current_scene == _active_scene:
		current_scene = null
	_active_scene = null
	await process_frame


func _set_viewport_size(size: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
	var window := get_root()
	window.size = size
	window.content_scale_size = size


func _settle_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
	await RenderingServer.frame_post_draw


func _image_crop_rect(rect: Rect2, image_size: Vector2i) -> Rect2i:
	var x0 := clampi(floori(rect.position.x), 0, maxi(0, image_size.x - 1))
	var y0 := clampi(floori(rect.position.y), 0, maxi(0, image_size.y - 1))
	var x1 := clampi(ceili(rect.end.x), x0 + 1, image_size.x)
	var y1 := clampi(ceili(rect.end.y), y0 + 1, image_size.y)
	return Rect2i(Vector2i(x0, y0), Vector2i(x1 - x0, y1 - y0))


func _scaled_image(image: Image) -> Image:
	var scaled := image.duplicate()
	scaled.resize(
		maxi(1, scaled.get_width() * CROP_SCALE),
		maxi(1, scaled.get_height() * CROP_SCALE),
		Image.INTERPOLATE_NEAREST
	)
	return scaled


func _image_stats(image: Image) -> Dictionary:
	var width := image.get_width()
	var height := image.get_height()
	var step_x = maxi(1, int(ceil(float(width) / 80.0)))
	var step_y = maxi(1, int(ceil(float(height) / 50.0)))
	var samples := 0
	var non_dark := 0
	var min_luminance := 1.0
	var max_luminance := 0.0

	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var color := image.get_pixel(x, y)
			var luminance := (color.r + color.g + color.b) / 3.0
			samples += 1
			if color.a > 0.1 and luminance > 0.03:
				non_dark += 1
			min_luminance = minf(min_luminance, luminance)
			max_luminance = maxf(max_luminance, luminance)

	return {
		"samples": samples,
		"non_dark_samples": non_dark,
		"non_dark_ratio": float(non_dark) / float(maxi(1, samples)),
		"min_luminance": min_luminance,
		"max_luminance": max_luminance,
		"luminance_range": max_luminance - min_luminance,
	}


func _draw_rect_outline(image: Image, rect: Rect2, color: Color, thickness: int) -> void:
	_draw_horizontal_line(image, rect.position.y, rect.position.x, rect.end.x, color, thickness)
	_draw_horizontal_line(image, rect.end.y, rect.position.x, rect.end.x, color, thickness)
	_draw_vertical_line(image, rect.position.x, rect.position.y, rect.end.y, color, thickness)
	_draw_vertical_line(image, rect.end.x, rect.position.y, rect.end.y, color, thickness)


func _draw_cross(image: Image, center: Vector2, color: Color, radius: int) -> void:
	_draw_horizontal_line(image, center.y, center.x - radius, center.x + radius, color, 2)
	_draw_vertical_line(image, center.x, center.y - radius, center.y + radius, color, 2)


func _draw_horizontal_line(image: Image, y: float, x0: float, x1: float, color: Color, thickness: int) -> void:
	var yy := roundi(y)
	var start_x := clampi(floori(minf(x0, x1)), 0, image.get_width() - 1)
	var end_x := clampi(ceili(maxf(x0, x1)), 0, image.get_width() - 1)
	var half := maxi(0, thickness / 2)
	for offset in range(-half, half + 1):
		var line_y := yy + offset
		if line_y < 0 or line_y >= image.get_height():
			continue
		for x in range(start_x, end_x + 1):
			image.set_pixel(x, line_y, color)


func _draw_vertical_line(image: Image, x: float, y0: float, y1: float, color: Color, thickness: int) -> void:
	var xx := roundi(x)
	var start_y := clampi(floori(minf(y0, y1)), 0, image.get_height() - 1)
	var end_y := clampi(ceili(maxf(y0, y1)), 0, image.get_height() - 1)
	var half := maxi(0, thickness / 2)
	for offset in range(-half, half + 1):
		var line_x := xx + offset
		if line_x < 0 or line_x >= image.get_width():
			continue
		for y in range(start_y, end_y + 1):
			image.set_pixel(line_x, y, color)


func _check(result: Dictionary, passed: bool, name: String, details: Dictionary = {}) -> bool:
	var check := {
		"name": name,
		"passed": passed,
	}
	if not details.is_empty():
		check["details"] = details
	result["checks"].append(check)

	if not passed:
		var failure := {
			"name": name,
			"details": details,
		}
		result["failures"].append(failure)
		_report["failures"].append({
			"level_id": result["level_id"],
			"name": name,
			"details": details,
		})
		print("Level grid audit failure [%s]: %s" % [result["level_id"], name])

	return passed


func _finalize_level(result: Dictionary) -> Dictionary:
	result["ok"] = result["failures"].is_empty()
	return result


func _write_reports() -> void:
	var json_path := _artifact_dir.path_join("report.json")
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(_report, "\t"))

	var md_path := _artifact_dir.path_join("report.md")
	var md_file := FileAccess.open(md_path, FileAccess.WRITE)
	if md_file != null:
		md_file.store_string(_format_markdown_report())


func _format_markdown_report() -> String:
	var lines := []
	lines.append("# Level Grid Audit Report")
	lines.append("")
	lines.append("- Status: %s" % ("PASS" if _report["ok"] else "FAIL"))
	lines.append("- Levels: %d" % _report["levels"].size())
	lines.append("- Failures: %d" % _report["failures"].size())
	lines.append("")
	lines.append("Overlay legend: green = buildable/tower, magenta = path/enemy, yellow = blocked/locked, cyan = board rect.")
	lines.append("")
	lines.append("## Manual Visual Review Checklist")
	lines.append("")
	lines.append("- [ ] Buildable-grid screenshots show a tower on every green/buildable cell and no tower on path cells.")
	lines.append("- [ ] Path-enemies screenshots show enemy markers centered on the intended road path from spawn to exit.")
	lines.append("- [ ] Board crops and overlays align with the rendered map background for each level.")
	lines.append("")

	for level in _report["levels"]:
		var summary: Dictionary = level["summary"]
		lines.append("## %s / %s" % [level["level_id"], level["display_name"]])
		lines.append("")
		lines.append("- Status: %s" % ("PASS" if level["ok"] else "FAIL"))
		lines.append("- Style: `%s`" % level["style_id"])
		lines.append("- Cells: buildable=%d, path=%d, blocked=%d, locked=%d" % [
			int(summary.get("buildable_cells", 0)),
			int(summary.get("path_cells", 0)),
			int(summary.get("blocked_cells", 0)),
			int(summary.get("locked_cells", 0)),
		])
		lines.append("- Placement attempts: %d, expected successes=%d" % [
			int(summary.get("placement_attempts", 0)),
			int(summary.get("expected_successes", 0)),
		])
		lines.append("- Path steps: %d, path distance=%.2f" % [
			int(summary.get("path_steps", 0)),
			float(summary.get("path_distance", 0.0)),
		])
		if not level["failures"].is_empty():
			lines.append("- Failures:")
			for failure in level["failures"]:
				lines.append("  - %s %s" % [failure["name"], JSON.stringify(failure.get("details", {}))])
		if not level["artifacts"].is_empty():
			lines.append("- Artifacts:")
			for artifact in level["artifacts"]:
				lines.append("  - %s: [screen](%s), [board](%s), [overlay](%s)" % [
					artifact["name"],
					_to_report_relative_path(artifact["screenshot"]),
					_to_report_relative_path(artifact["board_crop"]),
					_to_report_relative_path(artifact["board_overlay"]),
				])
		lines.append("")

	return "\n".join(lines) + "\n"


func _to_report_relative_path(path: String) -> String:
	var base := _artifact_dir
	if path.begins_with(base + "/"):
		return path.substr(base.length() + 1)
	return path


func _resolve_artifact_dir() -> String:
	var override := OS.get_environment("LEVEL_GRID_AUDIT_ARTIFACT_DIR")
	if override.is_empty():
		return ProjectSettings.globalize_path(DEFAULT_ARTIFACT_DIR)
	return override
