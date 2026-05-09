extends SceneTree

const START_SCENE_PATH := "res://scenes/start.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DEFAULT_ARTIFACT_DIR := "res://../ci-artifacts/ui-smoke/native"
const MIN_NON_DARK_RATIO := 0.05
const MIN_LUMINANCE_RANGE := 0.05

var _artifact_dir := ""
var _report := {}
var _failed := false


func _initialize() -> void:
	_artifact_dir = _resolve_artifact_dir()
	DirAccess.make_dir_recursive_absolute(_artifact_dir)
	_report = {
		"ok": true,
		"started_at_unix": Time.get_unix_time_from_system(),
		"viewports": [],
		"failures": [],
	}
	call_deferred("_run")


func _run() -> void:
	print("UI smoke artifacts: %s" % _artifact_dir)
	var viewports := _parse_viewports()
	for viewport in viewports:
		var result: Dictionary = await _run_viewport(viewport)
		_report["viewports"].append(result)
		if not result["ok"]:
			_failed = true

	_report["ok"] = not _failed
	_report["finished_at_unix"] = Time.get_unix_time_from_system()
	_write_reports()
	quit(1 if _failed else 0)


func _parse_viewports() -> Array:
	var override := OS.get_environment("UI_SMOKE_VIEWPORTS")
	if override.is_empty():
		return [
			{"name": "desktop", "size": Vector2i(1280, 720)},
			{"name": "mobile-landscape", "size": Vector2i(896, 414)},
			{"name": "square", "size": Vector2i(720, 720)},
		]

	var viewports := []
	for raw_entry in override.split(",", false):
		var parts := raw_entry.strip_edges().split("x", false)
		if parts.size() != 2:
			continue
		var width := int(parts[0])
		var height := int(parts[1])
		if width <= 0 or height <= 0:
			continue
		viewports.append({
			"name": "%dx%d" % [width, height],
			"size": Vector2i(width, height),
		})

	return viewports


func _run_viewport(viewport: Dictionary) -> Dictionary:
	var viewport_name := String(viewport["name"])
	var viewport_size := viewport["size"] as Vector2i
	var result := {
		"name": viewport_name,
		"size": {"width": viewport_size.x, "height": viewport_size.y},
		"ok": true,
		"checks": [],
		"failures": [],
	}

	print("Running UI smoke viewport %s (%dx%d)" % [viewport_name, viewport_size.x, viewport_size.y])
	_set_viewport_size(viewport_size)
	await _settle_frames(4)

	var start_loaded := await _load_start_scene(result)
	if not start_loaded:
		return _finalize_viewport(result)

	var start_scene := current_scene
	var title := start_scene.get_node_or_null("Title") as Label
	var start_button := start_scene.get_node_or_null("StartButton") as Button
	_check(result, title != null, "start title exists")
	_check(result, start_button != null, "start button exists")
	if title != null:
		_check(result, title.text == "WWL 大冒险 2", "start title text")
		_check_control_rect(result, title, viewport_size, "start title in viewport")
	if start_button != null:
		_check(result, start_button.text == "Start", "start button text")
		_check(result, start_button.visible, "start button visible")
		_check(result, start_button.size.x >= 120.0 and start_button.size.y >= 36.0, "start button clickable size")
		_check_control_rect(result, start_button, viewport_size, "start button in viewport")
		start_button.emit_signal("pressed")

	var main_loaded := await _wait_for_scene(MAIN_SCENE_PATH, 30)
	_check(result, main_loaded, "start button enters main scene")
	if not main_loaded:
		return _finalize_viewport(result)

	await _settle_frames(8)

	var main_scene := current_scene
	var board_view := main_scene.get_node_or_null("BoardView") as BoardView
	_check(result, board_view != null, "board view exists")
	if board_view == null:
		return _finalize_viewport(result)

	board_view.apply_responsive_layout(Vector2(viewport_size))
	await _settle_frames(4)

	_check_main_nodes(result, main_scene)
	_check_main_state(result, board_view)
	_check_layout(result, main_scene, board_view, viewport_size)
	await _exercise_minimum_play(result, main_scene, board_view)
	await _capture_screenshot(result, viewport_name)

	return _finalize_viewport(result)


func _load_start_scene(result: Dictionary) -> bool:
	var error := change_scene_to_file(START_SCENE_PATH)
	_check(result, error == OK, "load start scene")
	if error != OK:
		return false

	var loaded := await _wait_for_scene(START_SCENE_PATH, 30)
	_check(result, loaded, "start scene becomes current")
	return loaded


func _wait_for_scene(scene_path: String, max_frames: int) -> bool:
	for _index in range(max_frames):
		await process_frame
		if current_scene != null and current_scene.scene_file_path == scene_path:
			return true
	return false


func _settle_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
	await RenderingServer.frame_post_draw


func _set_viewport_size(size: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
	var window := get_root()
	window.size = size
	window.content_scale_size = size


func _check_main_nodes(result: Dictionary, main_scene: Node) -> void:
	var required_nodes := [
		"BoardView",
		"Hud/Gold",
		"Hud/Lives",
		"Hud/Wave",
		"Hud/MenuButton",
		"Hud/SingleTowerButton",
		"Hud/AreaTowerButton",
		"Hud/SlowTowerButton",
		"Hud/HudFrame",
		"Hud/TowerDeck",
		"Hud/Status",
		"Hud/Hint",
		"Overlay/Screen",
	]

	for node_path in required_nodes:
		_check(result, main_scene.get_node_or_null(node_path) != null, "main node exists: %s" % node_path)


func _check_main_state(result: Dictionary, board_view: BoardView) -> void:
	_check(result, board_view.board != null, "board initialized")
	_check(result, board_view.wallet != null, "wallet initialized")
	_check(result, board_view.combat_simulation != null, "combat simulation initialized")
	if board_view.board != null:
		_check(result, board_view.board.width == 10 and board_view.board.height == 8, "board size is 10x8")
	if board_view.wallet != null:
		_check(result, board_view.wallet.gold == 100, "initial gold is 100")
	if board_view.combat_simulation != null:
		_check(result, board_view.combat_simulation.player_life.lives == 10, "initial lives are 10")
	_check(result, board_view.flow_state == BoardView.FlowState.PLAYING, "main starts in playing state")
	_check(result, board_view.selected_tower_type == GameTower.Type.SINGLE_TARGET, "single tower selected by default")


func _check_layout(result: Dictionary, main_scene: Node, board_view: BoardView, viewport_size: Vector2i) -> void:
	var board_rect := Rect2(
		board_view.to_global(board_view.board_origin),
		Vector2(float(board_view.board.width) * board_view.cell_size, float(board_view.board.height) * board_view.cell_size)
	)
	_check_rect(result, board_rect, viewport_size, "board rect in viewport")
	_check(result, board_view.cell_size >= 1.0, "cell size is positive")

	var control_paths := [
		"Hud/Gold",
		"Hud/Lives",
		"Hud/Wave",
		"Hud/MenuButton",
		"Hud/SingleTowerButton",
		"Hud/AreaTowerButton",
		"Hud/SlowTowerButton",
	]

	for node_path in control_paths:
		var control := main_scene.get_node_or_null(node_path) as Control
		_check_control_rect(result, control, viewport_size, "%s in viewport" % node_path)
		if control != null and node_path.ends_with("Button"):
			_check(result, control.size.x >= 80.0 and control.size.y >= 32.0, "%s clickable size" % node_path)
			var control_rect := Rect2(control.global_position, control.size)
			_check(result, not board_rect.intersects(control_rect), "%s does not overlap board" % node_path)


func _exercise_minimum_play(result: Dictionary, main_scene: Node, board_view: BoardView) -> void:
	var gold_label := main_scene.get_node_or_null("Hud/Gold") as Label
	var wave_label := main_scene.get_node_or_null("Hud/Wave") as Label
	var buildable_cell := _find_buildable_cell(board_view)
	_check(result, buildable_cell != Vector2i(-1, -1), "found buildable cell")
	if buildable_cell == Vector2i(-1, -1):
		return

	var gold_before := board_view.wallet.gold
	_click_grid_cell(board_view, buildable_cell)
	await _settle_frames(2)

	var expected_gold := gold_before - board_view.economy_config.basic_tower_cost
	var placed_slot := board_view.board.get_slot(buildable_cell)
	_check(result, not placed_slot.occupant_id.is_empty(), "tower placed through board input")
	_check(result, board_view.wallet.gold == expected_gold, "gold spent after tower placement")
	if gold_label != null:
		_check(result, gold_label.text == "Gold: %d" % expected_gold, "gold label updates after placement")

	var path := board_view.get_default_path()
	if path.size() > 0:
		_click_grid_cell(board_view, path[0])
		await _settle_frames(2)
		_check(result, board_view.wallet.gold == expected_gold, "invalid path placement does not spend gold")
		if board_view.last_placement_result != null:
			_check(result, not board_view.last_placement_result.succeeded, "invalid path placement is rejected")

	board_view.combat_simulation.accumulator_seconds = 0.0
	board_view.wave_spawner.current_wave_state.spawn_elapsed_seconds = 0.0
	board_view._process(0.8)
	await _settle_frames(2)
	_check(result, board_view.combat_simulation.enemies.size() >= 1, "simulation spawns an enemy")
	if wave_label != null:
		_check(result, wave_label.text == "Wave: 1/3", "wave label remains readable")


func _find_buildable_cell(board_view: BoardView) -> Vector2i:
	for y in range(board_view.board.height):
		for x in range(board_view.board.width):
			var position := Vector2i(x, y)
			var slot := board_view.board.get_slot(position)
			if slot.slot_type == BoardSlot.Type.BUILDABLE and slot.is_empty():
				return position
	return Vector2i(-1, -1)


func _click_grid_cell(board_view: BoardView, grid_position: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = board_view.to_global(board_view.grid_to_local_rect(grid_position).get_center())
	board_view._unhandled_input(event)


func _capture_screenshot(result: Dictionary, viewport_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	_check(result, image != null, "capture screenshot")
	if image == null:
		return

	var screenshot_path := _artifact_dir.path_join("%s.png" % viewport_name)
	var save_error := image.save_png(screenshot_path)
	_check(result, save_error == OK, "save screenshot %s" % viewport_name)

	var stats := _image_stats(image)
	result["screenshot"] = {
		"path": screenshot_path,
		"width": image.get_width(),
		"height": image.get_height(),
		"stats": stats,
	}
	_check(result, stats["non_dark_ratio"] >= MIN_NON_DARK_RATIO, "screenshot is not blank")
	_check(result, stats["luminance_range"] >= MIN_LUMINANCE_RANGE, "screenshot has visual contrast")


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


func _check_control_rect(result: Dictionary, control: Control, viewport_size: Vector2i, name: String) -> void:
	if control == null:
		_check(result, false, name)
		return
	_check_rect(result, Rect2(control.global_position, control.size), viewport_size, name)


func _check_rect(result: Dictionary, rect: Rect2, viewport_size: Vector2i, name: String) -> void:
	var margin := 1.0
	var in_viewport := (
		rect.size.x > 0.0
		and rect.size.y > 0.0
		and rect.position.x >= -margin
		and rect.position.y >= -margin
		and rect.end.x <= float(viewport_size.x) + margin
		and rect.end.y <= float(viewport_size.y) + margin
	)
	_check(result, in_viewport, name, {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
		"viewport_width": viewport_size.x,
		"viewport_height": viewport_size.y,
	})


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
			"viewport": result["name"],
			"name": name,
			"details": details,
		})
		print("UI smoke failure [%s]: %s" % [result["name"], name])

	return passed


func _finalize_viewport(result: Dictionary) -> Dictionary:
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
		md_file.store_string(_render_markdown_report())


func _render_markdown_report() -> String:
	var lines := []
	lines.append("# UI Smoke Report")
	lines.append("")
	lines.append("- Status: %s" % ("PASS" if _report["ok"] else "FAIL"))
	lines.append("- Viewports: %d" % _report["viewports"].size())
	lines.append("- Failures: %d" % _report["failures"].size())
	lines.append("")
	for viewport in _report["viewports"]:
		lines.append("## %s" % viewport["name"])
		lines.append("")
		lines.append("- Status: %s" % ("PASS" if viewport["ok"] else "FAIL"))
		lines.append("- Size: %dx%d" % [viewport["size"]["width"], viewport["size"]["height"]])
		if viewport.has("screenshot"):
			lines.append("- Screenshot: `%s`" % viewport["screenshot"]["path"])
			lines.append("- Non-dark ratio: %.3f" % viewport["screenshot"]["stats"]["non_dark_ratio"])
			lines.append("- Luminance range: %.3f" % viewport["screenshot"]["stats"]["luminance_range"])
		if not viewport["failures"].is_empty():
			lines.append("- Failed checks:")
			for failure in viewport["failures"]:
				lines.append("  - %s" % failure["name"])
		lines.append("")
	return "\n".join(lines)


func _resolve_artifact_dir() -> String:
	var override := OS.get_environment("UI_SMOKE_ARTIFACT_DIR")
	if override.is_empty():
		return ProjectSettings.globalize_path(DEFAULT_ARTIFACT_DIR)
	if override.is_absolute_path():
		return override
	return ProjectSettings.globalize_path("res://../%s" % override)
