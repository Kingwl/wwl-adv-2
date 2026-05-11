extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DEFAULT_ARTIFACT_DIR := "res://../ci-artifacts/gameplay-smoke/native"
const DEFAULT_VIEWPORT_SIZE := Vector2i(1280, 720)
const PROJECTILE_VISUAL_DELAY_SECONDS := CombatSimulation.DEFAULT_FIXED_STEP_SECONDS * 5.0
const MIN_NON_DARK_RATIO := 0.05
const MIN_LUMINANCE_RANGE := 0.05
const CROP_SCALE := 2
const BOARD_CROP_MARGIN := 24.0
const FOCUS_CROP_MARGIN := 42.0
const OVERLAY_BOARD_COLOR := Color(0.10, 0.70, 1.0, 1.0)
const OVERLAY_TOWER_COLOR := Color(0.20, 1.0, 0.35, 1.0)
const OVERLAY_ENEMY_COLOR := Color(1.0, 0.15, 0.80, 1.0)
const OVERLAY_PROJECTILE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const OVERLAY_HEALTH_COLOR := Color(1.0, 0.78, 0.12, 1.0)
const OVERLAY_EFFECT_COLOR := Color(1.0, 0.32, 0.05, 1.0)
const OVERLAY_GUIDE_COLOR := Color(0.92, 1.0, 0.20, 1.0)

var _artifact_dir := ""
var _report := {}
var _failed := false


func _initialize() -> void:
	_artifact_dir = _resolve_artifact_dir()
	DirAccess.make_dir_recursive_absolute(_artifact_dir)
	_report = {
		"ok": true,
		"started_at_unix": Time.get_unix_time_from_system(),
		"scenarios": [],
		"failures": [],
	}
	call_deferred("_run")


func _run() -> void:
	print("Gameplay smoke artifacts: %s" % _artifact_dir)
	for viewport in _parse_viewports():
		for scenario_name in _parse_scenarios():
			var result: Dictionary = await _run_scenario(viewport, scenario_name)
			_report["scenarios"].append(result)
			if not result["ok"]:
				_failed = true

	_report["ok"] = not _failed
	_report["finished_at_unix"] = Time.get_unix_time_from_system()
	_write_reports()
	quit(1 if _failed else 0)


func _parse_viewports() -> Array:
	var override := OS.get_environment("GAMEPLAY_SMOKE_VIEWPORTS")
	if override.is_empty():
		return [{"name": "desktop", "size": DEFAULT_VIEWPORT_SIZE}]

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


func _parse_scenarios() -> Array:
	var default_scenarios := [
		"place_single_tower",
		"tower_upgrade_remove_refund",
		"single_tower_kill_reward",
		"area_tower_splash",
		"slow_tower_status",
		"flame_tower_burn",
		"poison_tower_dot",
		"tower_visual_catalog",
		"enemy_leak_life_loss",
		"wave_clear_victory",
		"defeat_on_zero_lives",
	]
	var override := OS.get_environment("GAMEPLAY_SMOKE_SCENARIOS")
	if override.is_empty():
		return default_scenarios

	var scenarios := []
	for raw_entry in override.split(",", false):
		var scenario_name := raw_entry.strip_edges()
		if not scenario_name.is_empty():
			scenarios.append(scenario_name)
	return scenarios


func _run_scenario(viewport: Dictionary, scenario_name: String) -> Dictionary:
	var viewport_name := String(viewport["name"])
	var viewport_size := viewport["size"] as Vector2i
	var result := {
		"name": scenario_name,
		"viewport": viewport_name,
		"size": {"width": viewport_size.x, "height": viewport_size.y},
		"ok": true,
		"checks": [],
		"failures": [],
		"checkpoints": [],
		"summary": _empty_summary(),
	}

	print("Running gameplay scenario %s on %s (%dx%d)" % [
		scenario_name,
		viewport_name,
		viewport_size.x,
		viewport_size.y,
	])
	_set_viewport_size(viewport_size)
	await _settle_frames(4)

	var board_view := await _load_main_board(result, viewport_size)
	if board_view == null:
		return _finalize_scenario(result)

	var scenario_dir := _artifact_dir.path_join("scenarios").path_join(scenario_name)
	DirAccess.make_dir_recursive_absolute(scenario_dir)

	match scenario_name:
		"place_single_tower":
			await _scenario_place_single_tower(result, viewport_name, scenario_dir, board_view)
		"tower_upgrade_remove_refund":
			await _scenario_tower_upgrade_remove_refund(result, viewport_name, scenario_dir, board_view)
		"single_tower_kill_reward":
			await _scenario_single_tower_kill_reward(result, viewport_name, scenario_dir, board_view)
		"area_tower_splash":
			await _scenario_area_tower_splash(result, viewport_name, scenario_dir, board_view)
		"slow_tower_status":
			await _scenario_slow_tower_status(result, viewport_name, scenario_dir, board_view)
		"flame_tower_burn":
			await _scenario_flame_tower_burn(result, viewport_name, scenario_dir, board_view)
		"poison_tower_dot":
			await _scenario_poison_tower_dot(result, viewport_name, scenario_dir, board_view)
		"tower_visual_catalog":
			await _scenario_tower_visual_catalog(result, viewport_name, scenario_dir, board_view)
		"enemy_leak_life_loss":
			await _scenario_enemy_leak_life_loss(result, viewport_name, scenario_dir, board_view)
		"wave_clear_victory":
			await _scenario_wave_clear_victory(result, viewport_name, scenario_dir, board_view)
		"defeat_on_zero_lives":
			await _scenario_defeat_on_zero_lives(result, viewport_name, scenario_dir, board_view)
		_:
			_check(result, false, "known gameplay scenario", {"scenario": scenario_name})

	_update_final_summary(result, board_view)
	return _finalize_scenario(result)


func _scenario_place_single_tower(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	var tower_cell := _preferred_tower_cell(board_view)
	var gold_before := board_view.get_session().wallet.gold
	board_view.select_tower_id("single")
	var placement := board_view.try_place_at_grid(tower_cell)
	await _settle_frames(2)

	_check(result, placement.succeeded, "single tower placement succeeds")
	_check(result, board_view.get_session().wallet.gold == gold_before - placement.transaction_result.amount, "placement spends gold")
	_check(result, board_view.get_session().placement_service.tower_registry.get_all_towers().size() == 1, "one tower registered")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "after-place", board_view)


func _scenario_tower_upgrade_remove_refund(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	var tower_cell := _preferred_tower_cell(board_view)
	board_view.select_tower_id("single")
	var placement := board_view.try_place_at_grid(tower_cell)
	await _settle_frames(2)
	_check(result, placement.succeeded, "tower placement succeeds before upgrade")

	var selected := board_view.select_tower_at_grid(tower_cell)
	await _settle_frames(2)
	_check(result, selected, "placed tower can be selected")
	_check(result, board_view.get_selected_tower_id() == placement.tower_id, "selected tower id matches placement")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "menu-open", board_view)

	var upgrade := board_view.upgrade_selected_tower()
	var session := board_view.get_session()
	var tower := session.placement_service.tower_registry.get_tower(placement.tower_id)
	await _settle_frames(2)
	_check(result, upgrade != null and upgrade.succeeded, "selected tower upgrade succeeds")
	_check(result, tower != null and tower.tier == 2, "upgraded tower reaches tier two")
	_check(result, session.wallet.gold == 35, "upgrade spends configured gold after placement")
	_check(result, session.combat_simulation.towers.size() == 1, "combat towers stay synced after upgrade")
	if session.combat_simulation.towers.size() == 1:
		_check(result, (session.combat_simulation.towers[0] as GameTower).tier == 2, "combat tower uses upgraded tier")
	_check(result, session.status_text == "Upgraded tower-1 to Single T2 for 40 gold.", "upgrade status text is visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "after-upgrade", board_view)

	var removal := board_view.remove_selected_tower()
	await _settle_frames(2)
	_check(result, removal != null and removal.succeeded, "selected tower removal succeeds")
	_check(result, removal != null and removal.refund_amount == 32, "removal refunds half of invested gold")
	_check(result, session.wallet.gold == 67, "wallet includes removal refund")
	_check(result, session.board.get_occupant_id(tower_cell).is_empty(), "board slot is empty after removal")
	_check(result, session.placement_service.tower_registry.get_all_towers().is_empty(), "registry is empty after removal")
	_check(result, session.combat_simulation.towers.is_empty(), "combat towers stay synced after removal")
	_check(result, board_view.get_selected_tower_id().is_empty(), "selection clears after removal")
	_check(result, session.status_text == "Removed tower-1 for 32 gold refund.", "removal status text is visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "after-remove", board_view)


func _scenario_single_tower_kill_reward(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.select_tower_id("single")
	board_view.try_place_at_grid(_preferred_tower_cell(board_view))
	var enemy := Enemy.new("smoke-enemy-1", 0.2, 10.0, 5)
	enemy.path_distance = 2.0
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "enemy-in-range", board_view)

	await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "single tower projectile becomes visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "projectile-visible", board_view)

	await _advance_until(result, board_view, func() -> bool: return enemy.defeated, 1.5)
	_check(result, enemy.defeated, "single tower defeats enemy")
	_check(result, board_view.get_session().wallet.gold == 80, "kill reward adds gold after placement")
	_check(result, board_view.get_session().last_reward_transaction_results.size() >= 1, "kill reward transaction recorded")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "enemy-defeated-reward", board_view)


func _scenario_area_tower_splash(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.select_tower_id("area")
	board_view.try_place_at_grid(_preferred_tower_cell(board_view))
	var first_enemy := Enemy.new("splash-enemy-1", 0.2, 6.0, 5)
	var second_enemy := Enemy.new("splash-enemy-2", 0.2, 6.0, 5)
	first_enemy.path_distance = 2.0
	second_enemy.path_distance = 2.3
	board_view.get_session().combat_simulation.enemies = [first_enemy, second_enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "cluster-in-range", board_view)

	await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "area projectile becomes visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "area-projectile-visible", board_view)

	await _advance_until(result, board_view, func() -> bool: return first_enemy.defeated and second_enemy.defeated, 1.5)
	_check(result, first_enemy.defeated and second_enemy.defeated, "area splash defeats grouped enemies")
	_check(result, board_view.get_session().wallet.gold == 85, "area splash kill rewards add gold")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "splash-impact-reward", board_view)


func _scenario_slow_tower_status(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.select_tower_id("slow")
	board_view.try_place_at_grid(_preferred_tower_cell(board_view))
	var enemy := Enemy.new("slow-enemy-1", 0.2, 20.0, 5)
	enemy.path_distance = 2.0
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "slow-target-in-range", board_view)

	await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "slow projectile becomes visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "slow-projectile-visible", board_view)

	var status_events_before := int(result["summary"]["status_events"])
	await _advance_until(
		result,
		board_view,
		func() -> bool: return int(result["summary"]["status_events"]) > status_events_before,
		1.5
	)
	var status_seen := int(result["summary"]["status_events"]) > status_events_before
	_check(result, status_seen, "slow projectile emits slow status event")
	_check(result, enemy.health < enemy.max_health and not enemy.defeated, "slow target remains alive after status hit")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "slow-impact-status", board_view)


func _scenario_flame_tower_burn(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.select_tower_id("flame")
	board_view.try_place_at_grid(_preferred_tower_cell(board_view))
	var enemy := Enemy.new(
		"flame-enemy-1",
		0.2,
		80.0,
		5,
		DamageTypes.ArmorType.HEAVY,
		DamageTypes.RaceType.UNDEAD
	)
	enemy.path_distance = 2.0
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "flame-target-in-range", board_view)

	await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "flame projectile becomes visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "flame-projectile-visible", board_view)

	var status_events_before := int(result["summary"]["status_events"])
	await _advance_until(
		result,
		board_view,
		func() -> bool: return int(result["summary"]["status_events"]) > status_events_before,
		1.5
	)
	var burn_seen := int(result["summary"]["status_events"]) > status_events_before
	var health_after_hit := enemy.health
	_check(result, burn_seen, "flame projectile emits burn status event")
	_check(result, enemy.status_effects.size() >= 1, "burn status is active on target")
	_check(result, health_after_hit < enemy.max_health and not enemy.defeated, "flame target remains alive after initial fire hit")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "flame-impact-burn", board_view)

	await _advance_until(
		result,
		board_view,
		func() -> bool: return enemy.health < health_after_hit,
		1.2
	)
	_check(result, enemy.health < health_after_hit, "burn DoT deals follow-up damage")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "burn-dot-damage", board_view)


func _scenario_poison_tower_dot(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.select_tower_id("poison")
	board_view.try_place_at_grid(_preferred_tower_cell(board_view))
	var enemy := Enemy.new(
		"poison-enemy-1",
		0.2,
		80.0,
		5,
		DamageTypes.ArmorType.LIGHT,
		DamageTypes.RaceType.HUMANOID
	)
	enemy.path_distance = 2.0
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "poison-target-in-range", board_view)

	await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "poison projectile becomes visible")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "poison-projectile-visible", board_view)

	var status_events_before := int(result["summary"]["status_events"])
	await _advance_until(
		result,
		board_view,
		func() -> bool: return int(result["summary"]["status_events"]) > status_events_before,
		1.5
	)
	var poison_seen := int(result["summary"]["status_events"]) > status_events_before
	var health_after_hit := enemy.health
	_check(result, poison_seen, "poison projectile emits poison status event")
	_check(result, enemy.status_effects.size() >= 1, "poison status is active on target")
	_check(result, health_after_hit < enemy.max_health and not enemy.defeated, "poison target remains alive after initial hit")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "poison-impact-status", board_view)

	await _advance_until(
		result,
		board_view,
		func() -> bool: return enemy.health < health_after_hit,
		1.2
	)
	_check(result, enemy.health < health_after_hit, "poison DoT deals follow-up damage")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "poison-dot-damage", board_view)


func _scenario_tower_visual_catalog(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	for spec in _tower_visual_specs():
		var tower_name := String(spec["name"])
		var tower_id := String(spec["tower_id"])
		board_view.restart_game()
		board_view.set_process(false)
		board_view.apply_responsive_layout(Vector2(get_root().size))
		_prepare_manual_combat(board_view)
		board_view.select_tower_id(tower_id)
		var placement := board_view.try_place_at_grid(_preferred_tower_cell(board_view))
		_check(result, placement.succeeded, "%s visual tower placement succeeds" % tower_name)

		var enemy := _visual_catalog_enemy(tower_name)
		enemy.path_distance = 2.0
		board_view.get_session().combat_simulation.enemies = [enemy]
		await _settle_frames(2)
		await _capture_checkpoint(result, viewport_name, scenario_dir, "%s-tower-ready" % tower_name, board_view)

		await _advance_gameplay(result, board_view, PROJECTILE_VISUAL_DELAY_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
		_check(result, board_view.get_session().combat_simulation.projectiles.size() >= 1, "%s projectile visual becomes visible" % tower_name)
		await _capture_checkpoint(result, viewport_name, scenario_dir, "%s-projectile-visible" % tower_name, board_view)

		var impact_events_before := int(result["summary"]["projectile_impacts"])
		await _advance_until(
			result,
			board_view,
			func() -> bool: return int(result["summary"]["projectile_impacts"]) > impact_events_before,
			2.0
		)
		var impact_seen := int(result["summary"]["projectile_impacts"]) > impact_events_before
		_check(result, impact_seen, "%s projectile impact event is emitted" % tower_name)
		_check(result, board_view.get_visual_state().attack_feedbacks.size() >= 1, "%s impact feedback visual becomes visible" % tower_name)
		await _capture_checkpoint(result, viewport_name, scenario_dir, "%s-impact-effect" % tower_name, board_view)


func _scenario_enemy_leak_life_loss(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	var enemy := Enemy.new("leak-enemy-1", 1.0)
	enemy.path_distance = board_view.get_session().path_follower.total_distance - 0.05
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "enemy-near-exit", board_view)

	await _advance_until(result, board_view, func() -> bool: return enemy.completed, 0.5)
	_check(result, enemy.completed, "enemy reaches exit")
	_check(result, board_view.get_session().combat_simulation.player_life.lives == 9, "leak removes one life")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "life-lost", board_view)


func _scenario_wave_clear_victory(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	var wave_spawner := WaveSpawner.new([
		WaveDefinition.new("smoke-wave", 1, 0.1, 10.0, 1.0, 5, 20),
	])
	wave_spawner.current_wave_state.spawned_count = 1
	board_view.get_session().wave_spawner = wave_spawner
	board_view.get_session().combat_simulation.wave_spawner = wave_spawner
	board_view.refresh_hud()
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "wave-ready-to-clear", board_view)

	await _advance_gameplay(result, board_view, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS, CombatSimulation.DEFAULT_FIXED_STEP_SECONDS)
	_check(result, board_view.get_session().combat_simulation.game_won, "wave clear sets victory")
	_check(result, board_view.get_session().flow_state == BoardGameSession.FlowState.WON, "victory overlay flow state")
	_check(result, board_view.get_session().wallet.gold == 120, "wave clear reward adds gold")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "victory-overlay", board_view)


func _scenario_defeat_on_zero_lives(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	board_view: BoardView
) -> void:
	_prepare_manual_combat(board_view)
	board_view.get_session().combat_simulation.player_life = PlayerLife.new(1)
	board_view.refresh_hud()
	var enemy := Enemy.new("defeat-enemy-1", 1.0)
	enemy.path_distance = board_view.get_session().path_follower.total_distance - 0.05
	board_view.get_session().combat_simulation.enemies = [enemy]
	await _settle_frames(2)
	await _capture_checkpoint(result, viewport_name, scenario_dir, "last-life-enemy-near-exit", board_view)

	await _advance_until(result, board_view, func() -> bool: return board_view.get_session().combat_simulation.game_failed, 0.5)
	_check(result, board_view.get_session().combat_simulation.game_failed, "life reaching zero sets defeat")
	_check(result, board_view.get_session().flow_state == BoardGameSession.FlowState.LOST, "defeat overlay flow state")
	await _capture_checkpoint(result, viewport_name, scenario_dir, "defeat-overlay", board_view)


func _load_main_board(result: Dictionary, viewport_size: Vector2i) -> BoardView:
	var previous_scene := current_scene
	var error := change_scene_to_file(MAIN_SCENE_PATH)
	_check(result, error == OK, "load main scene")
	if error != OK:
		return null

	var loaded := await _wait_for_scene(MAIN_SCENE_PATH, 30, previous_scene)
	_check(result, loaded, "main scene becomes current")
	if not loaded:
		return null

	await _settle_frames(8)
	var board_view := current_scene.get_node_or_null("BoardView") as BoardView
	_check(result, board_view != null, "board view exists")
	if board_view == null:
		return null

	board_view.set_process(false)
	board_view.apply_responsive_layout(Vector2(viewport_size))
	board_view.start_game()
	await _settle_frames(4)
	_check(result, board_view.get_session().wallet.gold == 100, "fresh scenario starts with 100 gold")
	_check(result, board_view.get_session().combat_simulation.player_life.lives == 10, "fresh scenario starts with 10 lives")
	_check(result, not board_view.get_session().combat_simulation.game_won, "fresh scenario is not won")
	_check(result, not board_view.get_session().combat_simulation.game_failed, "fresh scenario is not failed")
	return board_view


func _tower_visual_specs() -> Array:
	return TowerPresentationCatalog.new().get_visual_test_tower_specs()


func _visual_catalog_enemy(tower_name: String) -> Enemy:
	var race_type := DamageTypes.RaceType.BEAST
	if tower_name == "flame":
		race_type = DamageTypes.RaceType.UNDEAD
	return Enemy.new(
		"%s-visual-enemy" % tower_name,
		0.2,
		80.0,
		5,
		DamageTypes.ArmorType.HEAVY,
		race_type
	)


func _prepare_manual_combat(board_view: BoardView) -> void:
	board_view.get_session().combat_simulation.wave_spawner = null
	board_view.get_session().combat_simulation.enemies = []
	board_view.get_session().combat_simulation.projectiles = []
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0
	board_view.get_session().last_tick_results = []
	board_view.get_session().last_reward_transaction_results = []
	board_view.get_session().last_wave_reward_transaction_results = []
	board_view.get_visual_state().attack_feedbacks = []
	board_view.get_visual_state().enemy_death_animations = []
	board_view.get_session().sync_combat_towers()
	board_view.refresh_hud()
	board_view.queue_redraw()


func _preferred_tower_cell(board_view: BoardView) -> Vector2i:
	var preferred := Vector2i(2, 2)
	if _is_empty_buildable(board_view, preferred):
		return preferred

	for y in range(board_view.get_session().board.height):
		for x in range(board_view.get_session().board.width):
			var position := Vector2i(x, y)
			if _is_empty_buildable(board_view, position):
				return position
	return Vector2i(-1, -1)


func _is_empty_buildable(board_view: BoardView, position: Vector2i) -> bool:
	if board_view.get_session().board == null or not board_view.get_session().board.is_in_bounds(position):
		return false
	var slot := board_view.get_session().board.get_slot(position)
	return slot.slot_type == BoardSlot.Type.BUILDABLE and slot.is_empty()


func _advance_until(result: Dictionary, board_view: BoardView, predicate: Callable, max_seconds: float) -> void:
	var elapsed := 0.0
	var step := CombatSimulation.DEFAULT_FIXED_STEP_SECONDS
	while elapsed < max_seconds and not bool(predicate.call()):
		await _advance_gameplay(result, board_view, step, step)
		elapsed += step


func _advance_gameplay(result: Dictionary, board_view: BoardView, seconds: float, step: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var delta = minf(step, seconds - elapsed)
		board_view._process(delta)
		_accumulate_tick_trace(result, board_view.get_session().last_tick_results, delta)
		elapsed += delta
		await _settle_frames(1)


func _accumulate_tick_trace(result: Dictionary, tick_results: Array, delta_seconds: float) -> void:
	var summary: Dictionary = result["summary"]
	summary["elapsed_seconds"] = float(summary["elapsed_seconds"]) + delta_seconds
	summary["process_steps"] = int(summary["process_steps"]) + 1
	summary["tick_results"] = int(summary["tick_results"]) + tick_results.size()

	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue
		summary["spawned_enemies"] = int(summary["spawned_enemies"]) + tick_result.spawned_enemies.size()
		summary["enemy_leaks"] = int(summary["enemy_leaks"]) + tick_result.enemy_leak_events.size()
		summary["wave_clears"] = int(summary["wave_clears"]) + tick_result.wave_clear_events.size()
		summary["status_events"] = int(summary["status_events"]) + tick_result.status_events.size()
		summary["projectile_impacts"] = int(summary["projectile_impacts"]) + tick_result.projectile_impact_events.size()
		if tick_result.damage_result != null:
			summary["enemy_deaths"] = int(summary["enemy_deaths"]) + tick_result.damage_result.death_events.size()


func _capture_checkpoint(
	result: Dictionary,
	viewport_name: String,
	scenario_dir: String,
	checkpoint_name: String,
	board_view: BoardView
) -> void:
	board_view.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	_check(result, image != null, "capture checkpoint %s" % checkpoint_name)
	if image == null:
		return

	var base_name := "%s-%s" % [viewport_name, checkpoint_name]
	var screenshot_path := scenario_dir.path_join("%s.png" % base_name)
	var save_error := image.save_png(screenshot_path)
	_check(result, save_error == OK, "save checkpoint screenshot %s" % checkpoint_name)

	var board_rect := _board_global_rect(board_view)
	var crop_rect := _image_crop_rect(board_rect.grow(BOARD_CROP_MARGIN), Vector2i(image.get_width(), image.get_height()))
	var board_crop := image.get_region(crop_rect)
	var board_overlay := board_crop.duplicate()
	board_overlay.convert(Image.FORMAT_RGBA8)
	_draw_gameplay_overlay(board_overlay, Vector2(crop_rect.position), board_view)

	var scaled_crop := _scaled_image(board_crop)
	var scaled_overlay := _scaled_image(board_overlay)
	var board_crop_path := scenario_dir.path_join("%s-board.png" % base_name)
	var board_overlay_path := scenario_dir.path_join("%s-overlay.png" % base_name)
	var crop_error := scaled_crop.save_png(board_crop_path)
	var overlay_error := scaled_overlay.save_png(board_overlay_path)
	_check(result, crop_error == OK, "save board crop %s" % checkpoint_name)
	_check(result, overlay_error == OK, "save board overlay %s" % checkpoint_name)

	var focus_rect := _visual_focus_global_rect(board_view).grow(FOCUS_CROP_MARGIN)
	var focus_crop_rect := _image_crop_rect(focus_rect, Vector2i(image.get_width(), image.get_height()))
	var focus_crop := image.get_region(focus_crop_rect)
	var focus_overlay := focus_crop.duplicate()
	focus_overlay.convert(Image.FORMAT_RGBA8)
	_draw_gameplay_overlay(focus_overlay, Vector2(focus_crop_rect.position), board_view)
	var scaled_focus_crop := _scaled_image(focus_crop)
	var scaled_focus_overlay := _scaled_image(focus_overlay)
	var focus_crop_path := scenario_dir.path_join("%s-focus.png" % base_name)
	var focus_overlay_path := scenario_dir.path_join("%s-focus-overlay.png" % base_name)
	var focus_crop_error := scaled_focus_crop.save_png(focus_crop_path)
	var focus_overlay_error := scaled_focus_overlay.save_png(focus_overlay_path)
	_check(result, focus_crop_error == OK, "save focus crop %s" % checkpoint_name)
	_check(result, focus_overlay_error == OK, "save focus overlay %s" % checkpoint_name)

	var stats := _image_stats(image)
	_check(result, stats["non_dark_ratio"] >= MIN_NON_DARK_RATIO, "checkpoint screenshot is not blank")
	_check(result, stats["luminance_range"] >= MIN_LUMINANCE_RANGE, "checkpoint screenshot has visual contrast")

	result["checkpoints"].append({
		"name": checkpoint_name,
		"screenshot": {
			"path": screenshot_path,
			"width": image.get_width(),
			"height": image.get_height(),
			"stats": stats,
		},
		"board_crop": {
			"path": board_crop_path,
			"width": scaled_crop.get_width(),
			"height": scaled_crop.get_height(),
			"scale": CROP_SCALE,
		},
		"board_overlay": {
			"path": board_overlay_path,
			"width": scaled_overlay.get_width(),
			"height": scaled_overlay.get_height(),
			"scale": CROP_SCALE,
		},
		"focus_crop": {
			"path": focus_crop_path,
			"width": scaled_focus_crop.get_width(),
			"height": scaled_focus_crop.get_height(),
			"scale": CROP_SCALE,
		},
		"focus_overlay": {
			"path": focus_overlay_path,
			"width": scaled_focus_overlay.get_width(),
			"height": scaled_focus_overlay.get_height(),
			"scale": CROP_SCALE,
		},
		"state": _state_summary(board_view),
	})


func _draw_gameplay_overlay(image: Image, crop_origin: Vector2, board_view: BoardView) -> void:
	var board_rect := _board_global_rect(board_view)
	_draw_rect_outline(image, Rect2(board_rect.position - crop_origin, board_rect.size), OVERLAY_BOARD_COLOR, 2)

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
		var enemy_position := board_view.to_global(
			_grid_space_to_local(board_view, board_view.get_session().path_follower.get_grid_space_position(enemy))
		)
		_draw_cross(image, enemy_position - crop_origin, OVERLAY_ENEMY_COLOR, 8)
		var health_rect := _enemy_health_bar_rect(board_view, enemy)
		if health_rect.size.x > 0.0 and health_rect.size.y > 0.0:
			var global_health_rect := Rect2(board_view.to_global(health_rect.position), health_rect.size)
			_draw_rect_outline(image, Rect2(global_health_rect.position - crop_origin, global_health_rect.size), OVERLAY_HEALTH_COLOR, 2)

	for candidate in board_view.get_session().combat_simulation.projectiles:
		var projectile := candidate as CombatProjectile
		if projectile == null or not projectile.active:
			continue
		var projectile_position := board_view.to_global(_grid_space_to_local(board_view, projectile.position))
		var source_tower := board_view.get_session().placement_service.tower_registry.get_tower(projectile.tower_id)
		if source_tower != null:
			var source_rect := board_view.grid_to_local_rect(source_tower.grid_position)
			_draw_line(
				image,
				board_view.to_global(source_rect.get_center()) - crop_origin,
				projectile_position - crop_origin,
				OVERLAY_GUIDE_COLOR,
				1
			)
		var target_enemy := _enemy_by_id(board_view.get_session().combat_simulation.enemies, projectile.target_enemy_id)
		if target_enemy != null and not target_enemy.defeated:
			var target_position := board_view.to_global(
				_grid_space_to_local(board_view, board_view.get_session().path_follower.get_grid_space_position(target_enemy))
			)
			_draw_line(image, projectile_position - crop_origin, target_position - crop_origin, OVERLAY_GUIDE_COLOR, 1)
		_draw_cross(image, projectile_position - crop_origin, OVERLAY_PROJECTILE_COLOR, 5)

	for feedback in board_view.get_visual_state().attack_feedbacks:
		var center: Vector2 = feedback.get("position", Vector2.ZERO)
		var feedback_position := board_view.to_global(center)
		_draw_cross(image, feedback_position - crop_origin, OVERLAY_EFFECT_COLOR, 10)
		_draw_rect_outline(
			image,
			Rect2(feedback_position - crop_origin - Vector2(10.0, 10.0), Vector2(20.0, 20.0)),
			OVERLAY_EFFECT_COLOR,
			2
		)


func _visual_focus_global_rect(board_view: BoardView) -> Rect2:
	var has_rect := false
	var merged := Rect2()
	var cell_size := board_view.get_layout_metrics().cell_size

	for candidate in board_view.get_session().placement_service.tower_registry.get_all_towers():
		var tower := candidate as GameTower
		if tower == null:
			continue
		var local_tower_rect := board_view.grid_to_local_rect(tower.grid_position)
		var global_tower_rect := Rect2(board_view.to_global(local_tower_rect.position), local_tower_rect.size)
		if has_rect:
			merged = merged.merge(global_tower_rect)
		else:
			merged = global_tower_rect
			has_rect = true

	for candidate in board_view.get_session().combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.defeated:
			continue
		var enemy_position := board_view.to_global(
			_grid_space_to_local(board_view, board_view.get_session().path_follower.get_grid_space_position(enemy))
		)
		var enemy_radius := cell_size * 0.28
		var enemy_rect := Rect2(enemy_position - Vector2(enemy_radius, enemy_radius), Vector2(enemy_radius * 2.0, enemy_radius * 2.0))
		merged = merged.merge(enemy_rect) if has_rect else enemy_rect
		has_rect = true

	for candidate in board_view.get_session().combat_simulation.projectiles:
		var projectile := candidate as CombatProjectile
		if projectile == null or not projectile.active:
			continue
		var projectile_position := board_view.to_global(_grid_space_to_local(board_view, projectile.position))
		var projectile_radius := cell_size * 0.16
		var projectile_rect := Rect2(projectile_position - Vector2(projectile_radius, projectile_radius), Vector2(projectile_radius * 2.0, projectile_radius * 2.0))
		merged = merged.merge(projectile_rect) if has_rect else projectile_rect
		has_rect = true

	for feedback in board_view.get_visual_state().attack_feedbacks:
		var feedback_local_position: Vector2 = feedback.get("position", Vector2.ZERO)
		var feedback_position := board_view.to_global(feedback_local_position)
		var feedback_radius := cell_size * 0.32
		var feedback_rect := Rect2(feedback_position - Vector2(feedback_radius, feedback_radius), Vector2(feedback_radius * 2.0, feedback_radius * 2.0))
		merged = merged.merge(feedback_rect) if has_rect else feedback_rect
		has_rect = true

	return merged if has_rect else _board_global_rect(board_view)


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


func _enemy_health_bar_rect(board_view: BoardView, enemy: Enemy) -> Rect2:
	return board_view.get_renderer().get_enemy_health_bar_rect(
		board_view.get_session().path_follower,
		board_view.get_layout_metrics().board_origin,
		board_view.get_layout_metrics().cell_size,
		enemy
	)


func _enemy_by_id(enemies: Array, enemy_id: String) -> Enemy:
	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy != null and enemy.id == enemy_id:
			return enemy
	return null


func _state_summary(board_view: BoardView) -> Dictionary:
	var status_text := ""
	var hint_text := ""
	var gold_text := ""
	var lives_text := ""
	var wave_text := ""
	var scene := current_scene
	if scene != null:
		var status_label := scene.get_node_or_null("Hud/Status") as Label
		var hint_label := scene.get_node_or_null("Hud/Hint") as Label
		var gold_label := scene.get_node_or_null("Hud/Gold") as Label
		var lives_label := scene.get_node_or_null("Hud/Lives") as Label
		var wave_label := scene.get_node_or_null("Hud/Wave") as Label
		status_text = status_label.text if status_label != null else ""
		hint_text = hint_label.text if hint_label != null else ""
		gold_text = gold_label.text if gold_label != null else ""
		lives_text = lives_label.text if lives_label != null else ""
		wave_text = wave_label.text if wave_label != null else ""

	return {
		"gold": board_view.get_session().wallet.gold,
		"lives": board_view.get_session().combat_simulation.player_life.lives,
		"flow_state": _flow_state_name(board_view.get_session().flow_state),
		"game_won": board_view.get_session().combat_simulation.game_won,
		"game_failed": board_view.get_session().combat_simulation.game_failed,
		"tower_count": board_view.get_session().placement_service.tower_registry.get_all_towers().size(),
		"enemy_count": board_view.get_session().combat_simulation.enemies.size(),
		"visible_enemy_count": board_view.get_session().get_visible_enemies().size(),
		"projectile_count": board_view.get_session().combat_simulation.projectiles.size(),
		"status_text": status_text,
		"hint_text": hint_text,
		"gold_text": gold_text,
		"lives_text": lives_text,
		"wave_text": wave_text,
	}


func _empty_summary() -> Dictionary:
	return {
		"elapsed_seconds": 0.0,
		"process_steps": 0,
		"tick_results": 0,
		"spawned_enemies": 0,
		"enemy_deaths": 0,
		"enemy_leaks": 0,
		"wave_clears": 0,
		"status_events": 0,
		"projectile_impacts": 0,
		"gold": 0,
		"lives": 0,
		"flow_state": "unknown",
		"game_won": false,
		"game_failed": false,
		"tower_count": 0,
		"enemy_count": 0,
		"projectile_count": 0,
	}


func _update_final_summary(result: Dictionary, board_view: BoardView) -> void:
	var state := _state_summary(board_view)
	var summary: Dictionary = result["summary"]
	for key in state.keys():
		summary[key] = state[key]


func _flow_state_name(flow_state: int) -> String:
	match flow_state:
		BoardGameSession.FlowState.MENU:
			return "menu"
		BoardGameSession.FlowState.WON:
			return "won"
		BoardGameSession.FlowState.LOST:
			return "lost"
		_:
			return "playing"


func _wait_for_scene(scene_path: String, max_frames: int, previous_scene: Node = null) -> bool:
	for _index in range(max_frames):
		await process_frame
		if current_scene != null and current_scene != previous_scene and current_scene.scene_file_path == scene_path:
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


func _draw_line(image: Image, start: Vector2, end: Vector2, color: Color, thickness: int) -> void:
	var steps := maxi(1, ceili(start.distance_to(end)))
	var half := maxi(0, thickness / 2)
	for index in range(steps + 1):
		var t := float(index) / float(steps)
		var point := start.lerp(end, t)
		var px := roundi(point.x)
		var py := roundi(point.y)
		for offset_y in range(-half, half + 1):
			for offset_x in range(-half, half + 1):
				var x := px + offset_x
				var y := py + offset_y
				if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
					continue
				image.set_pixel(x, y, color)


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
			"scenario": result["name"],
			"viewport": result["viewport"],
			"name": name,
			"details": details,
		})
		print("Gameplay smoke failure [%s/%s]: %s" % [result["viewport"], result["name"], name])

	return passed


func _finalize_scenario(result: Dictionary) -> Dictionary:
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
	lines.append("# Gameplay Smoke Report")
	lines.append("")
	lines.append("- Status: %s" % ("PASS" if _report["ok"] else "FAIL"))
	lines.append("- Scenarios: %d" % _report["scenarios"].size())
	lines.append("- Failures: %d" % _report["failures"].size())
	lines.append("")
	lines.append("## Manual Gameplay Visual Review Checklist")
	lines.append("")
	lines.append("- [ ] Board and focus overlays: tower, enemy, projectile, impact-effect and health-bar markers align with the rendered objects.")
	lines.append("- [ ] Gameplay feedback: Gold/Lives/Wave/status/overlay text matches the checkpoint state summary.")
	lines.append("- [ ] Tower visual catalog: each tower has readable tower, projectile and impact-effect focus crops.")
	lines.append("- [ ] Combat readability: projectile, impact, death/reward, splash, slow and burn checkpoints are visually understandable.")
	lines.append("- [ ] Failure/victory readability: leak, defeat and victory feedback are visible without layout overlap.")
	lines.append("")
	lines.append("Overlay legend: cyan = board rect, green = tower, magenta = enemy, amber = health bar, white = projectile, orange = impact effect, yellow = attack guide.")
	lines.append("")
	for scenario in _report["scenarios"]:
		lines.append("## %s / %s" % [scenario["viewport"], scenario["name"]])
		lines.append("")
		lines.append("- Status: %s" % ("PASS" if scenario["ok"] else "FAIL"))
		var summary: Dictionary = scenario["summary"]
		lines.append("- Summary: gold=%s, lives=%s, flow=%s, enemies=%s, towers=%s, projectiles=%s, deaths=%s, leaks=%s, wave_clears=%s, status_events=%s" % [
			str(summary.get("gold", "")),
			str(summary.get("lives", "")),
			str(summary.get("flow_state", "")),
			str(summary.get("enemy_count", "")),
			str(summary.get("tower_count", "")),
			str(summary.get("projectile_count", "")),
			str(summary.get("enemy_deaths", "")),
			str(summary.get("enemy_leaks", "")),
			str(summary.get("wave_clears", "")),
			str(summary.get("status_events", "")),
		])
		if not scenario["failures"].is_empty():
			lines.append("- Failed checks:")
			for failure in scenario["failures"]:
				lines.append("  - %s" % failure["name"])
		if not scenario["checkpoints"].is_empty():
			lines.append("- Checkpoints:")
			for checkpoint in scenario["checkpoints"]:
				var state: Dictionary = checkpoint["state"]
				var links := "[screen](%s), [board](%s), [overlay](%s)" % [
					_artifact_link(checkpoint["screenshot"]["path"]),
					_artifact_link(checkpoint["board_crop"]["path"]),
					_artifact_link(checkpoint["board_overlay"]["path"]),
				]
				if checkpoint.has("focus_crop") and checkpoint.has("focus_overlay"):
					links += ", [focus](%s), [focus overlay](%s)" % [
						_artifact_link(checkpoint["focus_crop"]["path"]),
						_artifact_link(checkpoint["focus_overlay"]["path"]),
					]
				lines.append("  - %s: %s; gold=%s lives=%s flow=%s status=\"%s\"" % [
					checkpoint["name"],
					links,
					str(state["gold"]),
					str(state["lives"]),
					str(state["flow_state"]),
					state["status_text"],
				])
		lines.append("")
	return "\n".join(lines)


func _artifact_link(path: String) -> String:
	var prefix := _artifact_dir.trim_suffix("/") + "/"
	if path.begins_with(prefix):
		return path.substr(prefix.length())
	return path.get_file()


func _resolve_artifact_dir() -> String:
	var override := OS.get_environment("GAMEPLAY_SMOKE_ARTIFACT_DIR")
	if override.is_empty():
		return ProjectSettings.globalize_path(DEFAULT_ARTIFACT_DIR)
	if override.is_absolute_path():
		return override
	return ProjectSettings.globalize_path("res://../%s" % override)
