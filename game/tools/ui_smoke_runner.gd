extends SceneTree

const START_SCENE_PATH := "res://scenes/start.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DEFAULT_ARTIFACT_DIR := "res://../ci-artifacts/ui-smoke/native"
const MIN_NON_DARK_RATIO := 0.05
const MIN_LUMINANCE_RANGE := 0.05
const REVIEW_CROP_SCALE := 2
const REVIEW_CROP_MARGIN := 18.0
const OVERLAY_FRAME_COLOR := Color(0.10, 0.70, 1.0, 1.0)
const OVERLAY_CONTROL_COLOR := Color(1.0, 0.15, 0.80, 1.0)
const OVERLAY_ICON_COLOR := Color(1.0, 0.78, 0.12, 1.0)
const OVERLAY_GROUP_COLOR := Color(0.20, 1.0, 0.35, 1.0)
const OVERLAY_CENTER_COLOR := Color(1.0, 1.0, 1.0, 1.0)

enum ReviewSpecKind {
	MAIN,
	START,
	START_FULL,
	LEVEL_SELECT,
	TOWER_DECK,
	BOARD_PREVIEW,
	TOWER_ACTION,
	STATUS_HINT,
	OVERLAY,
}

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
		await _capture_current_review_artifacts(result, viewport_name, start_scene, "start screen", ReviewSpecKind.START)
		await _capture_current_review_artifacts(
			result,
			viewport_name,
			start_scene,
			"start screen full viewport",
			ReviewSpecKind.START_FULL,
			"start-screen-full",
			"Start screen full viewport"
		)
		start_button.emit_signal("pressed")

	await _settle_frames(4)
	var level_select_panel := start_scene.get_node_or_null("LevelSelectPanel") as VBoxContainer
	var first_level_button := start_scene.get_node_or_null("LevelSelectPanel/LevelButton1") as Button
	_check(result, level_select_panel != null, "level select panel exists")
	_check(result, level_select_panel != null and level_select_panel.visible, "start button opens level select")
	_check(result, first_level_button != null, "first level button exists")
	if first_level_button != null:
		_check(result, first_level_button.text == "1. Training Gate", "first level button text")
		_check(result, first_level_button.size.x >= 160.0 and first_level_button.size.y >= 30.0, "first level button clickable size")
		_check_control_rect(result, first_level_button, viewport_size, "first level button in viewport")
	if level_select_panel != null:
		_check_control_rect(result, level_select_panel, viewport_size, "level select panel in viewport")
		await _capture_current_review_artifacts(
			result,
			viewport_name,
			start_scene,
			"level select",
			ReviewSpecKind.LEVEL_SELECT,
			"level-select",
			"Level select"
		)
	if first_level_button != null:
		first_level_button.emit_signal("pressed")

	var main_loaded := await _wait_for_scene(MAIN_SCENE_PATH, 30)
	_check(result, main_loaded, "level select enters main scene")
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
	await _capture_screenshot(result, viewport_name, main_scene)
	await _capture_visual_state_artifacts(result, viewport_name, main_scene, board_view)

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
		"Hud/HudFrame",
		"Hud/TowerDeck",
		"Hud/TowerActionPanel",
		"Hud/TowerActionPanel/Title",
		"Hud/TowerActionPanel/UpgradeButton",
		"Hud/TowerActionPanel/RemoveButton",
		"Hud/Status",
		"Hud/Hint",
		"Overlay/Screen",
	]
	required_nodes.append_array(_tower_button_paths())

	for node_path in required_nodes:
		_check(result, main_scene.get_node_or_null(node_path) != null, "main node exists: %s" % node_path)


func _check_main_state(result: Dictionary, board_view: BoardView) -> void:
	_check(result, board_view.get_session().board != null, "board initialized")
	_check(result, board_view.get_session().wallet != null, "wallet initialized")
	_check(result, board_view.get_session().combat_simulation != null, "combat simulation initialized")
	if board_view.get_session().board != null:
		_check(result, board_view.get_session().board.width == 10 and board_view.get_session().board.height == 8, "board size is 10x8")
	if board_view.get_session().wallet != null:
		_check(result, board_view.get_session().wallet.gold == 100, "initial gold is 100")
	if board_view.get_session().combat_simulation != null:
		_check(result, board_view.get_session().combat_simulation.player_life.lives == 10, "initial lives are 10")
	_check(result, board_view.get_session().flow_state == BoardGameSession.FlowState.PLAYING, "main starts in playing state")
	_check(result, board_view.get_session().selected_tower_type == GameTower.Type.SINGLE_TARGET, "single tower selected by default")


func _check_layout(result: Dictionary, main_scene: Node, board_view: BoardView, viewport_size: Vector2i) -> void:
	var board_rect := Rect2(
		board_view.to_global(board_view.get_layout_metrics().board_origin),
		Vector2(float(board_view.get_session().board.width) * board_view.get_layout_metrics().cell_size, float(board_view.get_session().board.height) * board_view.get_layout_metrics().cell_size)
	)
	_check_rect(result, board_rect, viewport_size, "board rect in viewport")
	_check(result, board_view.get_layout_metrics().cell_size >= 1.0, "cell size is positive")

	var control_paths := [
		"Hud/Gold",
		"Hud/Lives",
		"Hud/Wave",
		"Hud/MenuButton",
	]
	control_paths.append_array(_tower_button_paths())

	for node_path in control_paths:
		var control := main_scene.get_node_or_null(node_path) as Control
		_check_control_rect(result, control, viewport_size, "%s in viewport" % node_path)
		if control != null and node_path.ends_with("Button"):
			_check(result, control.size.x >= 80.0 and control.size.y >= 32.0, "%s clickable size" % node_path)
			var control_rect := Rect2(control.global_position, control.size)
			_check(result, not board_rect.intersects(control_rect), "%s does not overlap board" % node_path)

	var message_paths := [
		"Hud/Status",
		"Hud/Hint",
	]
	for node_path in message_paths:
		var control := main_scene.get_node_or_null(node_path) as Control
		_check_control_rect(result, control, viewport_size, "%s in viewport" % node_path)
		if control != null:
			var control_rect := Rect2(control.global_position, control.size)
			_check(result, not board_rect.intersects(control_rect), "%s does not overlap board" % node_path)


func _exercise_minimum_play(result: Dictionary, main_scene: Node, board_view: BoardView) -> void:
	var gold_label := main_scene.get_node_or_null("Hud/Gold") as Label
	var wave_label := main_scene.get_node_or_null("Hud/Wave") as Label
	var buildable_cell := _find_buildable_cell(board_view)
	_check(result, buildable_cell != Vector2i(-1, -1), "found buildable cell")
	if buildable_cell == Vector2i(-1, -1):
		return

	var gold_before := board_view.get_session().wallet.gold
	_hover_grid_cell(board_view, buildable_cell)
	await _settle_frames(2)
	_hover_grid_cell(board_view, buildable_cell)
	_check(result, board_view.hover_grid_position == buildable_cell, "tower placement preview hover tracks buildable cell")
	_check(result, board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		buildable_cell,
		board_view.get_session().flow_state == BoardGameSession.FlowState.PLAYING and not board_view.get_session().gameplay_paused,
		board_view.get_session().selected_tower_definition_id
	), "tower placement preview visible on hovered buildable cell")
	await _capture_current_review_artifacts(
		result,
		String(result["name"]),
		main_scene,
		"tower placement preview",
		ReviewSpecKind.BOARD_PREVIEW,
		"tower-placement-preview",
		"Tower placement preview"
	)

	_click_grid_cell(board_view, buildable_cell)
	await _settle_frames(2)

	var expected_gold := gold_before - board_view.get_session().placement_service.get_build_cost_for_id(
		board_view.get_session().selected_tower_definition_id
	)
	var placed_slot := board_view.get_session().board.get_slot(buildable_cell)
	_check(result, not placed_slot.occupant_id.is_empty(), "tower placed through board input")
	_check(result, board_view.get_session().wallet.gold == expected_gold, "gold spent after tower placement")
	if gold_label != null:
		_check(result, gold_label.text == "Gold: %d" % expected_gold, "gold label updates after placement")

	_click_grid_cell(board_view, buildable_cell)
	await _settle_frames(2)
	var action_panel := main_scene.get_node_or_null("Hud/TowerActionPanel") as Panel
	var action_title := main_scene.get_node_or_null("Hud/TowerActionPanel/Title") as Label
	var upgrade_button := main_scene.get_node_or_null("Hud/TowerActionPanel/UpgradeButton") as Button
	var remove_button := main_scene.get_node_or_null("Hud/TowerActionPanel/RemoveButton") as Button
	_check(result, action_panel != null and action_panel.visible, "tower action menu opens from placed tower")
	if action_panel != null:
		_check_control_rect(result, action_panel, Vector2i(get_root().size), "tower action menu in viewport")
	if action_title != null:
		_check(result, action_title.text == "Single T1", "tower action title")
	if upgrade_button != null:
		_check(result, upgrade_button.text == "Upgrade 40g", "tower action upgrade text")
		_check(result, not upgrade_button.disabled, "tower action upgrade enabled")
	if remove_button != null:
		_check(result, remove_button.text == "Remove +12g", "tower action remove text")
		_check(result, not remove_button.disabled, "tower action remove enabled")

	var path := board_view.get_session().get_default_path()
	if path.size() > 0:
		_click_grid_cell(board_view, path[0])
		await _settle_frames(2)
		_check(result, action_panel == null or not action_panel.visible, "invalid path click closes tower action menu")
		_check(result, board_view.get_session().wallet.gold == expected_gold, "invalid path placement does not spend gold")
		if board_view.get_session().last_placement_result != null:
			_check(result, not board_view.get_session().last_placement_result.succeeded, "invalid path placement is rejected")

	board_view.get_session().combat_simulation.accumulator_seconds = 0.0
	board_view.get_session().wave_spawner.current_wave_state.spawn_elapsed_seconds = 0.0
	board_view._process(0.95)
	await _settle_frames(2)
	_check(result, board_view.get_session().combat_simulation.enemies.size() >= 1, "simulation spawns an enemy")
	if wave_label != null:
		_check(result, wave_label.text == "Wave: 1/8", "wave label remains readable")


func _find_buildable_cell(board_view: BoardView) -> Vector2i:
	for preferred_position in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(5, 2), Vector2i(1, 1)]:
		if _is_empty_buildable_cell(board_view, preferred_position):
			return preferred_position

	for y in range(board_view.get_session().board.height):
		for x in range(board_view.get_session().board.width):
			var position := Vector2i(x, y)
			if _is_empty_buildable_cell(board_view, position):
				return position
	return Vector2i(-1, -1)


func _is_empty_buildable_cell(board_view: BoardView, position: Vector2i) -> bool:
	if board_view == null or board_view.get_session().board == null:
		return false
	if not board_view.get_session().board.is_in_bounds(position):
		return false

	var slot := board_view.get_session().board.get_slot(position)
	return slot.slot_type == BoardSlot.Type.BUILDABLE and slot.is_empty()


func _find_occupied_cell(board_view: BoardView) -> Vector2i:
	for y in range(board_view.get_session().board.height):
		for x in range(board_view.get_session().board.width):
			var position := Vector2i(x, y)
			var slot := board_view.get_session().board.get_slot(position)
			if not slot.occupant_id.is_empty():
				return position
	return Vector2i(-1, -1)


func _click_grid_cell(board_view: BoardView, grid_position: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = board_view.to_global(board_view.grid_to_local_rect(grid_position).get_center())
	board_view._unhandled_input(event)


func _hover_grid_cell(board_view: BoardView, grid_position: Vector2i) -> void:
	board_view.hover_grid_position = grid_position
	board_view.queue_redraw()


func _capture_screenshot(result: Dictionary, viewport_name: String, main_scene: Node) -> void:
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
	_capture_review_artifacts(result, image, viewport_name, main_scene)


func _capture_review_artifacts(result: Dictionary, image: Image, viewport_name: String, main_scene: Node) -> void:
	_append_review_artifacts(
		result,
		image,
		viewport_name,
		main_scene,
		_review_crop_specs(main_scene, Vector2i(image.get_width(), image.get_height()))
	)


func _capture_current_review_artifacts(
	result: Dictionary,
	viewport_name: String,
	scene: Node,
	check_name: String,
	spec_kind: int,
	spec_name: String = "",
	spec_title: String = ""
) -> void:
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	_check(result, image != null, "capture review image %s" % check_name)
	if image == null:
		return

	var image_size := Vector2i(image.get_width(), image.get_height())
	_append_review_artifacts(
		result,
		image,
		viewport_name,
		scene,
		_review_specs_for_kind(scene, image_size, spec_kind, spec_name, spec_title)
	)


func _capture_visual_state_artifacts(
	result: Dictionary,
	viewport_name: String,
	main_scene: Node,
	board_view: BoardView
) -> void:
	var occupied_cell := _find_occupied_cell(board_view)
	if occupied_cell != Vector2i(-1, -1):
		board_view.select_tower_at_grid(occupied_cell)
		await _settle_frames(2)
		await _capture_current_review_artifacts(
			result,
			viewport_name,
			main_scene,
			"tower action menu",
			ReviewSpecKind.TOWER_ACTION,
			"tower-action-menu",
			"Tower action menu"
		)
		board_view.clear_tower_action_menu()
		await _settle_frames(1)

	for spec in TowerPresentationCatalog.new().get_visual_test_tower_specs():
		var tower_name := String(spec["name"])
		var tower_id := String(spec["tower_id"])
		board_view.select_tower_id(tower_id)
		await _settle_frames(2)
		await _capture_current_review_artifacts(
			result,
			viewport_name,
			main_scene,
			"%s tower selected" % tower_name,
			ReviewSpecKind.TOWER_DECK,
			"tower-deck-%s-selected" % tower_name,
			"Tower deck: %s selected" % tower_name.capitalize()
		)

	board_view.get_session().wallet.gold = 0
	board_view.refresh_hud()
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"tower deck insufficient gold",
		ReviewSpecKind.TOWER_DECK,
		"tower-deck-insufficient-gold",
		"Tower deck: insufficient gold"
	)

	board_view.get_session().wallet.gold = 100
	board_view.refresh_hud()
	board_view.set_status_message(BoardMessage.kill_reward("enemy-1", 5))
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"reward status",
		ReviewSpecKind.STATUS_HINT,
		"status-reward",
		"Status and hint: reward"
	)

	board_view.set_status_message(BoardMessage.enemy_leaked(9))
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"leak status",
		ReviewSpecKind.STATUS_HINT,
		"status-leak",
		"Status and hint: leak"
	)

	board_view.start_game()
	await _settle_frames(2)
	board_view.open_pause_menu()
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"pause overlay",
		ReviewSpecKind.OVERLAY,
		"pause-overlay",
		"Pause overlay"
	)

	board_view.resume_game()
	await _settle_frames(2)
	board_view.show_victory_screen()
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"victory overlay",
		ReviewSpecKind.OVERLAY,
		"victory-overlay",
		"Victory overlay"
	)

	board_view.show_defeat_screen()
	await _settle_frames(2)
	await _capture_current_review_artifacts(
		result,
		viewport_name,
		main_scene,
		"defeat overlay",
		ReviewSpecKind.OVERLAY,
		"defeat-overlay",
		"Defeat overlay"
	)


func _append_review_artifacts(
	result: Dictionary,
	image: Image,
	viewport_name: String,
	scene: Node,
	specs: Array
) -> void:
	var artifacts: Array = result.get("review_artifacts", [])
	for spec in specs:
		var artifact := _write_review_crop(result, image, viewport_name, scene, spec)
		if not artifact.is_empty():
			artifacts.append(artifact)
	result["review_artifacts"] = artifacts


func _review_specs_for_kind(
	scene: Node,
	image_size: Vector2i,
	spec_kind: int,
	spec_name: String = "",
	spec_title: String = ""
) -> Array:
	match spec_kind:
		ReviewSpecKind.START:
			return [_start_screen_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.START_FULL:
			return [_start_screen_full_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.LEVEL_SELECT:
			return [_level_select_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.TOWER_DECK:
			return [_tower_deck_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.BOARD_PREVIEW:
			return [_board_preview_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.TOWER_ACTION:
			return [_tower_action_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.STATUS_HINT:
			return [_status_hint_review_spec(scene, image_size, spec_name, spec_title)]
		ReviewSpecKind.OVERLAY:
			return [_overlay_review_spec(scene, image_size, spec_name, spec_title)]
		_:
			return _review_crop_specs(scene, image_size)


func _review_crop_specs(main_scene: Node, image_size: Vector2i) -> Array:
	return [
		_hud_resources_review_spec(main_scene, image_size),
		_status_hint_review_spec(main_scene, image_size),
		_tower_deck_review_spec(main_scene, image_size),
	]


func _tower_button_paths() -> Array:
	var paths := []
	for spec in TowerPresentationCatalog.new().get_tower_button_specs():
		paths.append(String(spec["node_path"]))
	return paths


func _hud_resources_review_spec(main_scene: Node, image_size: Vector2i) -> Dictionary:
	return {
		"name": "hud-resources",
		"title": "HUD resources",
		"rect": _stat_resources_crop_rect(main_scene, image_size),
		"controls": [
			{"path": "Hud/HudFrame", "kind": "frame"},
			{"path": "Hud/GoldIcon", "kind": "icon"},
			{"path": "Hud/Gold", "kind": "control"},
			{"path": "Hud/LivesIcon", "kind": "icon"},
			{"path": "Hud/Lives", "kind": "control"},
			{"path": "Hud/WaveIcon", "kind": "icon"},
			{"path": "Hud/Wave", "kind": "control"},
		],
		"groups": [
			["Hud/GoldIcon", "Hud/Gold"],
			["Hud/LivesIcon", "Hud/Lives"],
			["Hud/WaveIcon", "Hud/Wave"],
		],
	}


func _status_hint_review_spec(
	main_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	return {
		"name": spec_name if not spec_name.is_empty() else "status-hint",
		"title": spec_title if not spec_title.is_empty() else "Status and hint",
		"rect": _status_hint_crop_rect(main_scene, image_size),
		"controls": [
			{"path": "Hud/HudFrame", "kind": "frame"},
			{"path": "Hud/Status", "kind": "control"},
			{"path": "Hud/Hint", "kind": "control"},
			{"path": "Hud/MenuButton", "kind": "control"},
		],
		"groups": [
			["Hud/Status"],
			["Hud/Hint"],
		],
	}


func _tower_deck_review_spec(
	main_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	var tower_button_paths := _tower_button_paths()
	var deck_paths := ["Hud/TowerDeck"]
	deck_paths.append_array(tower_button_paths)
	var controls := [
		{"path": "Hud/TowerDeck", "kind": "frame"},
	]
	var groups := []
	for path in tower_button_paths:
		controls.append({"path": path, "kind": "control"})
		groups.append([path])

	return {
		"name": spec_name if not spec_name.is_empty() else "tower-deck",
		"title": spec_title if not spec_title.is_empty() else "Tower deck",
		"rect": _expanded_control_group_rect(main_scene, deck_paths, image_size),
		"controls": controls,
		"groups": groups,
	}


func _tower_action_review_spec(
	main_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	return {
		"name": spec_name if not spec_name.is_empty() else "tower-action-menu",
		"title": spec_title if not spec_title.is_empty() else "Tower action menu",
		"rect": _expanded_control_group_rect(main_scene, [
			"Hud/TowerActionPanel",
			"Hud/TowerActionPanel/Title",
			"Hud/TowerActionPanel/Preview",
			"Hud/TowerActionPanel/UpgradeButton",
			"Hud/TowerActionPanel/RemoveButton",
		], image_size),
		"controls": [
			{"path": "Hud/TowerActionPanel", "kind": "frame"},
			{"path": "Hud/TowerActionPanel/Title", "kind": "control"},
			{"path": "Hud/TowerActionPanel/Preview", "kind": "control"},
			{"path": "Hud/TowerActionPanel/UpgradeButton", "kind": "control"},
			{"path": "Hud/TowerActionPanel/RemoveButton", "kind": "control"},
		],
		"groups": [
			["Hud/TowerActionPanel/Title", "Hud/TowerActionPanel/Preview"],
			["Hud/TowerActionPanel/UpgradeButton", "Hud/TowerActionPanel/RemoveButton"],
		],
	}


func _board_preview_review_spec(
	main_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	var board_view := main_scene.get_node_or_null("BoardView") as BoardView
	var preview_rect := _tower_preview_global_rect(board_view)
	return {
		"name": spec_name if not spec_name.is_empty() else "tower-placement-preview",
		"title": spec_title if not spec_title.is_empty() else "Tower placement preview",
		"rect": _tower_preview_crop_rect(board_view, image_size),
		"controls": [],
		"groups": [],
		"rects": [
			{"rect": preview_rect, "kind": "group"},
		],
	}


func _start_screen_review_spec(
	start_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	return {
		"name": spec_name if not spec_name.is_empty() else "start-screen",
		"title": spec_title if not spec_title.is_empty() else "Start screen",
		"rect": _expanded_control_group_rect(start_scene, [
			"MenuFrame",
			"CrestIcon",
			"Title",
			"StartButton",
		], image_size),
		"controls": [
			{"path": "MenuFrame", "kind": "frame"},
			{"path": "CrestIcon", "kind": "icon"},
			{"path": "Title", "kind": "control"},
			{"path": "StartButton", "kind": "control"},
		],
		"groups": [
			["MenuFrame", "CrestIcon", "Title", "StartButton"],
			["Title"],
			["StartButton"],
		],
	}


func _start_screen_full_review_spec(
	start_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	return {
		"name": spec_name if not spec_name.is_empty() else "start-screen-full",
		"title": spec_title if not spec_title.is_empty() else "Start screen full viewport",
		"rect": Rect2(Vector2.ZERO, Vector2(image_size)),
		"scale": 1,
		"controls": [
			{"path": "MenuFrame", "kind": "frame"},
			{"path": "CrestIcon", "kind": "icon"},
			{"path": "Title", "kind": "control"},
			{"path": "StartButton", "kind": "control"},
		],
		"groups": [
			["MenuFrame", "CrestIcon", "Title", "StartButton"],
			["Title"],
			["StartButton"],
		],
	}


func _level_select_review_spec(
	start_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	var level_button_paths := []
	for index in range(1, 6):
		level_button_paths.append("LevelSelectPanel/LevelButton%d" % index)
	var paths := [
		"MenuFrame",
		"CrestIcon",
		"Title",
		"LevelSelectPanel",
		"LevelSelectPanel/LevelPrompt",
		"LevelSelectPanel/LevelBackButton",
	]
	paths.append_array(level_button_paths)
	var controls := [
		{"path": "MenuFrame", "kind": "frame"},
		{"path": "CrestIcon", "kind": "icon"},
		{"path": "Title", "kind": "control"},
		{"path": "LevelSelectPanel", "kind": "frame"},
		{"path": "LevelSelectPanel/LevelPrompt", "kind": "control"},
	]
	var groups := [
		["MenuFrame", "CrestIcon", "Title", "LevelSelectPanel"],
		["LevelSelectPanel/LevelPrompt"],
	]
	for button_path in level_button_paths:
		controls.append({"path": button_path, "kind": "control"})
		groups.append([button_path])
	controls.append({"path": "LevelSelectPanel/LevelBackButton", "kind": "control"})
	groups.append(["LevelSelectPanel/LevelBackButton"])

	return {
		"name": spec_name if not spec_name.is_empty() else "level-select",
		"title": spec_title if not spec_title.is_empty() else "Level select",
		"rect": _expanded_control_group_rect(start_scene, paths, image_size),
		"controls": controls,
		"groups": groups,
	}


func _overlay_review_spec(
	main_scene: Node,
	image_size: Vector2i,
	spec_name: String = "",
	spec_title: String = ""
) -> Dictionary:
	return {
		"name": spec_name if not spec_name.is_empty() else "overlay",
		"title": spec_title if not spec_title.is_empty() else "Overlay",
		"rect": _expanded_control_group_rect(main_scene, [
			"Overlay/Screen/Panel",
			"Overlay/Screen/Panel/Title",
			"Overlay/Screen/Panel/Message",
			"Overlay/Screen/Panel/PrimaryButton",
			"Overlay/Screen/Panel/SecondaryButton",
		], image_size),
		"controls": [
			{"path": "Overlay/Screen/Panel", "kind": "frame"},
			{"path": "Overlay/Screen/Panel/Title", "kind": "control"},
			{"path": "Overlay/Screen/Panel/Message", "kind": "control"},
			{"path": "Overlay/Screen/Panel/PrimaryButton", "kind": "control"},
			{"path": "Overlay/Screen/Panel/SecondaryButton", "kind": "control"},
		],
		"groups": [
			["Overlay/Screen/Panel/Title"],
			["Overlay/Screen/Panel/Message"],
			["Overlay/Screen/Panel/PrimaryButton", "Overlay/Screen/Panel/SecondaryButton"],
		],
	}


func _write_review_crop(result: Dictionary, image: Image, viewport_name: String, main_scene: Node, spec: Dictionary) -> Dictionary:
	var rect := spec["rect"] as Rect2
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_check(result, false, "review crop has valid rect: %s" % spec["name"])
		return {}

	var crop_rect := _image_crop_rect(rect, Vector2i(image.get_width(), image.get_height()))
	var crop := image.get_region(crop_rect)
	var overlay := crop.duplicate()
	overlay.convert(Image.FORMAT_RGBA8)
	_draw_review_overlay(overlay, Vector2(crop_rect.position), main_scene, spec)

	var scale := int(spec.get("scale", REVIEW_CROP_SCALE))
	var crop_scaled := _scaled_review_image(crop, scale)
	var overlay_scaled := _scaled_review_image(overlay, scale)
	var crop_path := _artifact_dir.path_join("%s-%s.png" % [viewport_name, spec["name"]])
	var overlay_path := _artifact_dir.path_join("%s-%s-overlay.png" % [viewport_name, spec["name"]])
	var crop_error := crop_scaled.save_png(crop_path)
	var overlay_error := overlay_scaled.save_png(overlay_path)
	_check(result, crop_error == OK, "save review crop %s" % spec["name"])
	_check(result, overlay_error == OK, "save review overlay %s" % spec["name"])

	return {
		"name": spec["name"],
		"title": spec["title"],
		"crop": {
			"path": crop_path,
			"width": crop_scaled.get_width(),
			"height": crop_scaled.get_height(),
			"scale": REVIEW_CROP_SCALE,
		},
		"overlay": {
			"path": overlay_path,
			"width": overlay_scaled.get_width(),
			"height": overlay_scaled.get_height(),
			"scale": REVIEW_CROP_SCALE,
		},
	}


func _stat_resources_crop_rect(main_scene: Node, image_size: Vector2i) -> Rect2:
	var resources_rect := _control_group_rect(main_scene, [
		"Hud/GoldIcon",
		"Hud/Gold",
		"Hud/LivesIcon",
		"Hud/Lives",
		"Hud/WaveIcon",
		"Hud/Wave",
	])
	if resources_rect.size.x <= 0.0 or resources_rect.size.y <= 0.0:
		return Rect2()

	var hud_frame := _control_rect(main_scene, "Hud/HudFrame")
	var top := resources_rect.position.y - REVIEW_CROP_MARGIN
	var bottom := resources_rect.end.y + REVIEW_CROP_MARGIN
	if hud_frame.size.y > 0.0:
		top = hud_frame.position.y - REVIEW_CROP_MARGIN * 0.5
		bottom = hud_frame.end.y + REVIEW_CROP_MARGIN * 0.5

	return _clamp_rect(
		Rect2(
			Vector2(resources_rect.position.x - REVIEW_CROP_MARGIN, top),
			Vector2(resources_rect.size.x + REVIEW_CROP_MARGIN * 2.0, bottom - top)
		),
		image_size
	)


func _status_hint_crop_rect(main_scene: Node, image_size: Vector2i) -> Rect2:
	var message_rect := _control_group_rect(main_scene, [
		"Hud/Status",
		"Hud/Hint",
	])
	if message_rect.size.x <= 0.0 or message_rect.size.y <= 0.0:
		return Rect2()

	var hud_frame := _control_rect(main_scene, "Hud/HudFrame")
	if hud_frame.size.y > 0.0 and message_rect.position.y <= hud_frame.end.y + REVIEW_CROP_MARGIN:
		message_rect = Rect2(
			Vector2(message_rect.position.x, minf(message_rect.position.y, hud_frame.position.y)),
			Vector2(message_rect.size.x, maxf(message_rect.end.y, hud_frame.end.y) - minf(message_rect.position.y, hud_frame.position.y))
		)
	return _clamp_rect(message_rect.grow(REVIEW_CROP_MARGIN), image_size)


func _expanded_control_group_rect(main_scene: Node, paths: Array, image_size: Vector2i) -> Rect2:
	var rect := _control_group_rect(main_scene, paths)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	return _clamp_rect(rect.grow(REVIEW_CROP_MARGIN), image_size)


func _tower_preview_crop_rect(board_view: BoardView, image_size: Vector2i) -> Rect2:
	var preview_rect := _tower_preview_global_rect(board_view)
	if preview_rect.size.x <= 0.0 or preview_rect.size.y <= 0.0:
		return Rect2()

	var margin := maxf(REVIEW_CROP_MARGIN, preview_rect.size.x * 0.75)
	return _clamp_rect(preview_rect.grow(margin), image_size)


func _tower_preview_global_rect(board_view: BoardView) -> Rect2:
	if board_view == null or board_view.hover_grid_position == BoardView.INVALID_GRID_POSITION:
		return Rect2()

	var local_rect := board_view.grid_to_local_rect(board_view.hover_grid_position)
	var canvas_transform := board_view.get_global_transform_with_canvas()
	var screen_position := canvas_transform * local_rect.position
	var screen_end := canvas_transform * local_rect.end
	return Rect2(screen_position, screen_end - screen_position).abs()


func _control_group_rect(main_scene: Node, paths: Array) -> Rect2:
	var has_rect := false
	var merged := Rect2()
	for node_path in paths:
		var rect := _control_rect(main_scene, String(node_path))
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if has_rect:
			merged = merged.merge(rect)
		else:
			merged = rect
			has_rect = true
	return merged if has_rect else Rect2()


func _control_rect(main_scene: Node, node_path: String) -> Rect2:
	var control := main_scene.get_node_or_null(node_path) as Control
	if control == null:
		return Rect2()
	return Rect2(control.global_position, control.size)


func _clamp_rect(rect: Rect2, image_size: Vector2i) -> Rect2:
	var x0 := clampf(rect.position.x, 0.0, float(maxi(0, image_size.x - 1)))
	var y0 := clampf(rect.position.y, 0.0, float(maxi(0, image_size.y - 1)))
	var x1 := clampf(rect.end.x, x0 + 1.0, float(image_size.x))
	var y1 := clampf(rect.end.y, y0 + 1.0, float(image_size.y))
	return Rect2(Vector2(x0, y0), Vector2(x1 - x0, y1 - y0))


func _image_crop_rect(rect: Rect2, image_size: Vector2i) -> Rect2i:
	var x0 := clampi(floori(rect.position.x), 0, maxi(0, image_size.x - 1))
	var y0 := clampi(floori(rect.position.y), 0, maxi(0, image_size.y - 1))
	var x1 := clampi(ceili(rect.end.x), x0 + 1, image_size.x)
	var y1 := clampi(ceili(rect.end.y), y0 + 1, image_size.y)
	return Rect2i(Vector2i(x0, y0), Vector2i(x1 - x0, y1 - y0))


func _scaled_review_image(image: Image, scale: int = REVIEW_CROP_SCALE) -> Image:
	var scaled := image.duplicate()
	scaled.resize(
		maxi(1, scaled.get_width() * scale),
		maxi(1, scaled.get_height() * scale),
		Image.INTERPOLATE_NEAREST
	)
	return scaled


func _draw_review_overlay(image: Image, crop_origin: Vector2, main_scene: Node, spec: Dictionary) -> void:
	for rect_entry in spec.get("rects", []):
		var rect: Rect2 = rect_entry.get("rect", Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var local_direct_rect := Rect2(rect.position - crop_origin, rect.size)
		var direct_color := _overlay_color_for_kind(String(rect_entry.get("kind", "control")))
		_draw_rect_outline(image, local_direct_rect, direct_color, 2)
		_draw_horizontal_line(image, local_direct_rect.get_center().y, local_direct_rect.position.x, local_direct_rect.end.x, OVERLAY_CENTER_COLOR, 1)

	for entry in spec.get("controls", []):
		var node_path := String(entry["path"])
		var rect := _control_rect(main_scene, node_path)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var local_rect := Rect2(rect.position - crop_origin, rect.size)
		var color := _overlay_color_for_kind(String(entry["kind"]))
		_draw_rect_outline(image, local_rect, color, 2)

	for group in spec.get("groups", []):
		var group_rect := _control_group_rect(main_scene, group)
		if group_rect.size.x <= 0.0 or group_rect.size.y <= 0.0:
			continue
		var local_group := Rect2(group_rect.position - crop_origin, group_rect.size)
		_draw_rect_outline(image, local_group, OVERLAY_GROUP_COLOR, 1)
		_draw_horizontal_line(image, local_group.get_center().y, local_group.position.x, local_group.end.x, OVERLAY_CENTER_COLOR, 1)


func _overlay_color_for_kind(kind: String) -> Color:
	match kind:
		"frame":
			return OVERLAY_FRAME_COLOR
		"icon":
			return OVERLAY_ICON_COLOR
		"group":
			return OVERLAY_GROUP_COLOR
		_:
			return OVERLAY_CONTROL_COLOR


func _draw_rect_outline(image: Image, rect: Rect2, color: Color, thickness: int) -> void:
	_draw_horizontal_line(image, rect.position.y, rect.position.x, rect.end.x, color, thickness)
	_draw_horizontal_line(image, rect.end.y, rect.position.x, rect.end.x, color, thickness)
	_draw_vertical_line(image, rect.position.x, rect.position.y, rect.end.y, color, thickness)
	_draw_vertical_line(image, rect.end.x, rect.position.y, rect.end.y, color, thickness)


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
	lines.append("## Manual UI Review Checklist")
	lines.append("")
	lines.append("Use the crop and overlay artifacts below before accepting UI or visual polish changes.")
	lines.append("")
	lines.append("- [ ] HUD resources: Gold/Lives/Wave text and icons sit visually centered in the HUD slot.")
	lines.append("- [ ] Status/hint: text is readable, centered in its intended area, and not clipped or crowded by Menu, board, or tower deck.")
	lines.append("- [ ] Status variants: reward and leak messages remain readable in compact and desktop layouts.")
	lines.append("- [ ] Tower deck: cards fit the viewport, selected/disabled states are readable, and card text does not collide with icons or frames.")
	lines.append("- [ ] Tower placement preview: hovered buildable tile shows a readable translucent preview of the selected tower.")
	lines.append("- [ ] Tower action menu: floating Upgrade/Remove panel appears beside the selected tower, stays in viewport, and its button text is readable.")
	lines.append("- [ ] Start and overlays: start, level select, pause, victory, and defeat panels keep title, message, and buttons centered and readable.")
	lines.append("- [ ] Compact viewports: top HUD, board, and bottom/side tower deck remain visually separated.")
	lines.append("")
	lines.append("Overlay legend: cyan = frame/panel rect, magenta = label/button rect, amber = icon rect, green = grouped control rect, white = grouped control centerline.")
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
		if viewport.has("review_artifacts") and not viewport["review_artifacts"].is_empty():
			lines.append("- Review crops:")
			for artifact in viewport["review_artifacts"]:
				lines.append(
					"  - %s: [crop](%s), [overlay](%s)"
					% [
						artifact["title"],
						_artifact_link(artifact["crop"]["path"]),
						_artifact_link(artifact["overlay"]["path"]),
					]
				)
		lines.append("")
	return "\n".join(lines)


func _artifact_link(path: String) -> String:
	return path.get_file()


func _resolve_artifact_dir() -> String:
	var override := OS.get_environment("UI_SMOKE_ARTIFACT_DIR")
	if override.is_empty():
		return ProjectSettings.globalize_path(DEFAULT_ARTIFACT_DIR)
	if override.is_absolute_path():
		return override
	return ProjectSettings.globalize_path("res://../%s" % override)
