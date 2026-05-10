class_name BoardRenderer
extends RefCounted

const ENEMY_RADIUS_FACTOR := 0.18
const ENEMY_HEALTH_BAR_WIDTH_FACTOR := 0.54
const ENEMY_HEALTH_BAR_HEIGHT_FACTOR := 0.075
const ENEMY_HEALTH_BAR_OFFSET_FACTOR := 0.08
const TOWER_SPRITE_SIZE_FACTOR := 1.0
const ENEMY_SPRITE_SIZE_FACTOR := 0.64
const PROJECTILE_SPRITE_SIZE_FACTOR := 0.46
const IMPACT_SPRITE_SIZE_FACTOR := 0.90
const ENEMY_WALK_FRAME_SECONDS := 0.16


func draw(
	canvas: CanvasItem,
	board: Board,
	visible_enemies: Array,
	combat_simulation: CombatSimulation,
	path_follower: PathFollower,
	placement_service: TowerPlacementService,
	map_style_definition: MapStyleDefinition,
	board_map_renderer: BoardMapRenderer,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float,
	hover_grid_position: Vector2i,
	last_placement_result: PlacementResult
) -> void:
	if canvas == null or board == null:
		return

	_draw_scene_background(canvas, asset_catalog)
	_draw_board_shadow(canvas, board, board_origin, cell_size)
	_draw_board_background(canvas, board, map_style_definition, board_map_renderer, board_origin, cell_size)

	for y in range(board.height):
		for x in range(board.width):
			var grid_position := Vector2i(x, y)
			var slot := board.get_slot(grid_position)
			_draw_slot(
				canvas,
				board,
				placement_service,
				combat_simulation,
				path_follower,
				visual_state,
				asset_catalog,
				board_origin,
				cell_size,
				grid_position,
				slot,
				hover_grid_position,
				last_placement_result
			)

	_draw_enemies(canvas, visible_enemies, path_follower, visual_state, asset_catalog, board_origin, cell_size)
	_draw_projectiles(canvas, combat_simulation, path_follower, asset_catalog, board_origin, cell_size)
	_draw_attack_feedbacks(canvas, visual_state, asset_catalog, cell_size)


func grid_space_to_local(board_origin: Vector2, cell_size: float, grid_space_position: Vector2) -> Vector2:
	return board_origin + grid_space_position * cell_size


func enemy_local_position(path_follower: PathFollower, board_origin: Vector2, cell_size: float, enemy: Enemy) -> Vector2:
	if path_follower == null or enemy == null:
		return board_origin
	return grid_space_to_local(board_origin, cell_size, path_follower.get_grid_space_position(enemy))


func get_tower_sprite_texture(
	tower_type: GameTower.Type,
	_tower_id: String,
	_visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog
) -> Texture2D:
	if asset_catalog == null:
		return null

	match tower_type:
		GameTower.Type.AREA:
			return asset_catalog.area_tower_texture
		GameTower.Type.SLOW:
			return asset_catalog.slow_tower_texture

	return asset_catalog.single_tower_texture


func get_enemy_sprite_texture(enemy: Enemy, visual_state: BoardVisualState, asset_catalog: BoardAssetCatalog) -> Texture2D:
	if asset_catalog == null:
		return null

	if not asset_catalog.enemy_walk_textures.is_empty():
		var animation_position := 0.0
		if visual_state != null:
			animation_position = visual_state.visual_elapsed_seconds
		if enemy != null:
			animation_position += enemy.path_distance * 0.08
		var frame_index := floori(fmod(animation_position / ENEMY_WALK_FRAME_SECONDS, float(asset_catalog.enemy_walk_textures.size())))
		return asset_catalog.enemy_walk_textures[frame_index] as Texture2D

	return asset_catalog.basic_enemy_texture


func get_attack_feedback_texture(tower_type: GameTower.Type, progress: float, asset_catalog: BoardAssetCatalog) -> Texture2D:
	if asset_catalog == null:
		return null

	match tower_type:
		GameTower.Type.AREA:
			return _texture_for_progress(asset_catalog.area_impact_textures, progress)
		GameTower.Type.SLOW:
			return _texture_for_progress(asset_catalog.slow_impact_textures, progress)

	return _texture_for_progress(asset_catalog.single_projectile_textures, progress)


func get_projectile_texture(projectile: CombatProjectile, asset_catalog: BoardAssetCatalog) -> Texture2D:
	if projectile == null:
		return null

	var progress := fmod(projectile.elapsed_seconds / 0.24, 1.0)
	return get_attack_feedback_texture(projectile.tower_type, progress, asset_catalog)


func projectile_draw_rotation(projectile: CombatProjectile, path_follower: PathFollower, combat_simulation: CombatSimulation) -> float:
	if projectile == null or path_follower == null:
		return 0.0

	var target := get_enemy_by_id(combat_simulation, projectile.target_enemy_id)
	if target == null:
		return 0.0

	var target_position := path_follower.get_grid_space_position(target)
	return projectile.position.angle_to_point(target_position)


func tower_draw_rotation(tower: GameTower, combat_simulation: CombatSimulation, path_follower: PathFollower) -> float:
	if tower == null or combat_simulation == null or path_follower == null:
		return 0.0

	var target := _select_current_target(tower, combat_simulation, path_follower)
	if target == null:
		return 0.0

	var tower_position := Vector2(float(tower.grid_position.x) + 0.5, float(tower.grid_position.y) + 0.5)
	var target_position := path_follower.get_grid_space_position(target)
	return tower_position.angle_to_point(target_position)


func get_enemy_health_ratio(enemy: Enemy) -> float:
	if enemy == null or enemy.max_health <= 0.0:
		return 0.0

	return clampf(enemy.health / enemy.max_health, 0.0, 1.0)


func get_enemy_health_bar_rect(path_follower: PathFollower, board_origin: Vector2, cell_size: float, enemy: Enemy) -> Rect2:
	if enemy == null or path_follower == null:
		return Rect2()

	var enemy_position := enemy_local_position(path_follower, board_origin, cell_size, enemy)
	var bar_width := maxf(18.0, cell_size * ENEMY_HEALTH_BAR_WIDTH_FACTOR)
	var bar_height := maxf(4.0, cell_size * ENEMY_HEALTH_BAR_HEIGHT_FACTOR)
	var bar_offset := maxf(4.0, cell_size * ENEMY_HEALTH_BAR_OFFSET_FACTOR)
	var bar_position := Vector2(
		enemy_position.x - bar_width * 0.5,
		enemy_position.y - enemy_radius(cell_size) - bar_offset - bar_height
	)

	return Rect2(bar_position, Vector2(bar_width, bar_height))


func enemy_radius(cell_size: float) -> float:
	return cell_size * ENEMY_RADIUS_FACTOR


func impact_feedback_color(tower_type: GameTower.Type) -> Color:
	match tower_type:
		GameTower.Type.AREA:
			return Color(1.0, 0.48, 0.18, 1.0)
		GameTower.Type.SLOW:
			return Color(0.35, 0.70, 1.0, 1.0)

	return Color(1.0, 0.86, 0.25, 1.0)


func get_enemy_by_id(combat_simulation: CombatSimulation, enemy_id: String) -> Enemy:
	if combat_simulation == null:
		return null

	for candidate in combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy != null and enemy.id == enemy_id:
			return enemy

	return null


func get_tower_by_id(placement_service: TowerPlacementService, combat_simulation: CombatSimulation, tower_id: String) -> GameTower:
	if placement_service != null and placement_service.tower_registry != null:
		var placed_tower := placement_service.tower_registry.get_tower(tower_id)
		if placed_tower != null:
			return placed_tower

	if combat_simulation != null:
		for candidate in combat_simulation.towers:
			var tower := candidate as GameTower
			if tower != null and tower.id == tower_id:
				return tower

	return null


func _draw_scene_background(canvas: CanvasItem, asset_catalog: BoardAssetCatalog) -> void:
	var viewport_rect := canvas.get_viewport_rect()
	if asset_catalog != null and asset_catalog.scene_background_texture != null:
		canvas.draw_texture_rect(asset_catalog.scene_background_texture, viewport_rect, true, Color(0.46, 0.56, 0.66, 1.0))
		canvas.draw_rect(viewport_rect, Color(0.006, 0.012, 0.016, 0.42), true)
		return

	canvas.draw_rect(viewport_rect, Color(0.035, 0.045, 0.055, 1.0), true)


func _draw_board_shadow(canvas: CanvasItem, board: Board, board_origin: Vector2, cell_size: float) -> void:
	var shadow_padding := maxf(4.0, cell_size * 0.125)
	var shadow_rect := _board_rect(board, board_origin, cell_size).grow(shadow_padding)
	canvas.draw_rect(shadow_rect, Color(0.06, 0.07, 0.08, 1.0), true)


func _draw_board_background(
	canvas: CanvasItem,
	board: Board,
	map_style_definition: MapStyleDefinition,
	board_map_renderer: BoardMapRenderer,
	board_origin: Vector2,
	cell_size: float
) -> void:
	var board_rect := _board_rect(board, board_origin, cell_size)
	if board_map_renderer != null and map_style_definition != null:
		board_map_renderer.draw_board(canvas, board, map_style_definition, board_origin, cell_size)
		return

	canvas.draw_rect(board_rect, Color(0.15, 0.17, 0.16, 1.0), true)


func _draw_slot(
	canvas: CanvasItem,
	board: Board,
	placement_service: TowerPlacementService,
	combat_simulation: CombatSimulation,
	path_follower: PathFollower,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float,
	grid_position: Vector2i,
	slot: BoardSlot,
	hover_grid_position: Vector2i,
	last_placement_result: PlacementResult
) -> void:
	var rect := Rect2(
		board_origin + Vector2(float(grid_position.x) * cell_size, float(grid_position.y) * cell_size),
		Vector2(cell_size, cell_size)
	)
	var inner_rect := rect.grow(-1)

	if slot.occupant_id != "":
		_draw_tower_sprite(canvas, placement_service, combat_simulation, path_follower, visual_state, asset_catalog, cell_size, slot.occupant_id, inner_rect)

	if grid_position == hover_grid_position:
		var outline_color := Color(0.85, 0.95, 1.0, 1.0)
		if not board.is_in_bounds(grid_position) or not slot.is_buildable() or not slot.is_empty():
			outline_color = Color(1.0, 0.30, 0.24, 1.0)
		canvas.draw_rect(inner_rect.grow(-1), outline_color, false, 3.0)

	if last_placement_result != null and grid_position == last_placement_result.position and not last_placement_result.succeeded:
		canvas.draw_rect(inner_rect.grow(-2), Color(1.0, 0.18, 0.15, 1.0), false, 4.0)


func _draw_tower_sprite(
	canvas: CanvasItem,
	placement_service: TowerPlacementService,
	combat_simulation: CombatSimulation,
	path_follower: PathFollower,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	cell_size: float,
	tower_id: String,
	slot_rect: Rect2
) -> void:
	var tower := get_tower_by_id(placement_service, combat_simulation, tower_id)
	var tower_type := GameTower.Type.SINGLE_TARGET
	if tower != null:
		tower_type = tower.tower_type

	var texture := get_tower_sprite_texture(tower_type, tower_id, visual_state, asset_catalog)
	if texture != null:
		canvas.draw_circle(slot_rect.get_center() + Vector2(0.0, cell_size * 0.16), cell_size * 0.25, Color(0.04, 0.035, 0.03, 0.45))
		_draw_oriented_sprite_texture(
			canvas,
			texture,
			slot_rect.get_center(),
			cell_size * TOWER_SPRITE_SIZE_FACTOR,
			tower_draw_rotation(tower, combat_simulation, path_follower)
		)
		return

	canvas.draw_circle(slot_rect.get_center(), cell_size * 0.25, _tower_fill_color(placement_service, combat_simulation, tower_id))
	canvas.draw_circle(slot_rect.get_center(), cell_size * 0.14, Color(0.15, 0.25, 0.32, 1.0))


func _draw_enemies(
	canvas: CanvasItem,
	visible_enemies: Array,
	path_follower: PathFollower,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float
) -> void:
	for enemy in visible_enemies:
		_draw_enemy(canvas, path_follower, visual_state, asset_catalog, board_origin, cell_size, enemy)

	if visual_state != null:
		_draw_enemy_death_animations(canvas, visual_state, asset_catalog, cell_size)


func _draw_enemy(
	canvas: CanvasItem,
	path_follower: PathFollower,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float,
	enemy: Enemy
) -> void:
	if enemy == null or path_follower == null:
		return

	var enemy_position := enemy_local_position(path_follower, board_origin, cell_size, enemy)
	var radius := enemy_radius(cell_size)
	var texture := get_enemy_sprite_texture(enemy, visual_state, asset_catalog)

	if texture != null:
		canvas.draw_circle(enemy_position + Vector2(0.0, radius * 0.48), radius * 0.92, Color(0.04, 0.035, 0.03, 0.55))
		_draw_sprite_texture(canvas, texture, enemy_position, cell_size * ENEMY_SPRITE_SIZE_FACTOR)
	else:
		canvas.draw_circle(enemy_position, radius + 3.0, Color(0.08, 0.07, 0.06, 0.9))
		canvas.draw_circle(enemy_position, radius, Color(0.88, 0.20, 0.16, 1.0))

	_draw_enemy_health_bar(canvas, path_follower, board_origin, cell_size, enemy)


func _draw_enemy_death_animations(
	canvas: CanvasItem,
	visual_state: BoardVisualState,
	asset_catalog: BoardAssetCatalog,
	cell_size: float
) -> void:
	for animation in visual_state.enemy_death_animations:
		var position: Vector2 = animation.get("position", Vector2.ZERO)
		var elapsed: float = animation.get("elapsed", 0.0)
		var duration: float = animation.get("duration", BoardVisualState.ENEMY_DEATH_ANIMATION_SECONDS)
		var progress := clampf(elapsed / duration, 0.0, 0.9999)
		var texture := _texture_for_progress(asset_catalog.enemy_death_textures if asset_catalog != null else [], progress)
		var alpha := 1.0 - clampf(progress, 0.0, 1.0)
		if texture != null:
			_draw_sprite_texture(canvas, texture, position, cell_size * ENEMY_SPRITE_SIZE_FACTOR, Color(1.0, 1.0, 1.0, alpha))
		else:
			canvas.draw_circle(position, cell_size * 0.20 * (1.0 + progress), Color(1.0, 0.24, 0.16, alpha))


func _draw_enemy_health_bar(
	canvas: CanvasItem,
	path_follower: PathFollower,
	board_origin: Vector2,
	cell_size: float,
	enemy: Enemy
) -> void:
	var ratio := get_enemy_health_ratio(enemy)
	if ratio >= 0.999:
		return

	var bar_rect := get_enemy_health_bar_rect(path_follower, board_origin, cell_size, enemy)
	canvas.draw_rect(bar_rect.grow(1), Color(0.03, 0.02, 0.018, 0.86), true)
	canvas.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), _enemy_health_bar_fill_color(ratio), true)


func _draw_projectiles(
	canvas: CanvasItem,
	combat_simulation: CombatSimulation,
	path_follower: PathFollower,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float
) -> void:
	if combat_simulation == null:
		return

	for projectile in combat_simulation.projectiles:
		_draw_projectile(canvas, combat_simulation, path_follower, asset_catalog, board_origin, cell_size, projectile)


func _draw_projectile(
	canvas: CanvasItem,
	combat_simulation: CombatSimulation,
	path_follower: PathFollower,
	asset_catalog: BoardAssetCatalog,
	board_origin: Vector2,
	cell_size: float,
	projectile: CombatProjectile
) -> void:
	if projectile == null or not projectile.active:
		return

	var projectile_position := grid_space_to_local(board_origin, cell_size, projectile.position)
	var texture := get_projectile_texture(projectile, asset_catalog)
	if texture != null:
		_draw_oriented_sprite_texture(
			canvas,
			texture,
			projectile_position,
			cell_size * PROJECTILE_SPRITE_SIZE_FACTOR,
			projectile_draw_rotation(projectile, path_follower, combat_simulation)
		)
		return

	canvas.draw_circle(projectile_position, maxf(3.0, cell_size * 0.045), impact_feedback_color(projectile.tower_type))


func _draw_attack_feedbacks(canvas: CanvasItem, visual_state: BoardVisualState, asset_catalog: BoardAssetCatalog, cell_size: float) -> void:
	if visual_state == null:
		return

	for feedback in visual_state.attack_feedbacks:
		var elapsed: float = feedback.get("elapsed", 0.0)
		var duration: float = feedback.get("duration", BoardVisualState.ATTACK_FEEDBACK_DURATION_SECONDS)
		var progress := clampf(elapsed / duration, 0.0, 0.9999)
		var center: Vector2 = feedback.get("position", Vector2.ZERO)
		var tower_type: GameTower.Type = feedback.get("tower_type", GameTower.Type.SINGLE_TARGET)
		var texture := get_attack_feedback_texture(tower_type, progress, asset_catalog)
		var alpha := 1.0 - clampf(progress, 0.0, 1.0)
		if texture != null:
			_draw_sprite_texture(canvas, texture, center, cell_size * IMPACT_SPRITE_SIZE_FACTOR, Color(1.0, 1.0, 1.0, alpha))
		else:
			var color: Color = feedback.get("color", impact_feedback_color(tower_type))
			color.a = alpha
			canvas.draw_circle(center, cell_size * (0.18 + progress * 0.18), color)


func _board_rect(board: Board, board_origin: Vector2, cell_size: float) -> Rect2:
	return Rect2(board_origin, Vector2(float(board.width) * cell_size, float(board.height) * cell_size))


func _select_current_target(tower: GameTower, combat_simulation: CombatSimulation, path_follower: PathFollower) -> Enemy:
	if combat_simulation.tower_attack_service == null:
		return null

	var tower_config := combat_simulation.tower_attack_service.tower_config
	var targeting_service := combat_simulation.tower_attack_service.targeting_service
	if tower_config == null or targeting_service == null:
		return null

	var stats := tower_config.get_stats(tower.tower_type, tower.tier)
	return targeting_service.select_target(tower, stats, combat_simulation.enemies, path_follower)


func _texture_for_progress(textures: Array, progress: float) -> Texture2D:
	if textures.is_empty():
		return null

	var index := clampi(floori(clampf(progress, 0.0, 0.9999) * float(textures.size())), 0, textures.size() - 1)
	return textures[index] as Texture2D


func _draw_sprite_texture(
	canvas: CanvasItem,
	texture: Texture2D,
	center: Vector2,
	max_size: float,
	draw_modulate: Color = Color.WHITE
) -> void:
	if texture == null:
		return

	canvas.draw_texture_rect(texture, _sprite_draw_rect(texture, center, max_size), false, draw_modulate)


func _draw_oriented_sprite_texture(
	canvas: CanvasItem,
	texture: Texture2D,
	center: Vector2,
	max_size: float,
	draw_rotation: float,
	draw_modulate: Color = Color.WHITE
) -> void:
	if texture == null:
		return

	var rect := _sprite_draw_rect(texture, Vector2.ZERO, max_size)
	canvas.draw_set_transform(center, draw_rotation, Vector2.ONE)
	canvas.draw_texture_rect(texture, rect, false, draw_modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sprite_draw_rect(texture: Texture2D, center: Vector2, max_size: float) -> Rect2:
	if texture == null:
		return Rect2(center, Vector2.ZERO)

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or max_size <= 0.0:
		return Rect2(center, Vector2.ZERO)

	var draw_scale := minf(max_size / texture_size.x, max_size / texture_size.y)
	var draw_size := texture_size * draw_scale
	return Rect2(center - draw_size * 0.5, draw_size)


func _enemy_health_bar_fill_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.22, 0.82, 0.30, 1.0)
	if ratio > 0.25:
		return Color(1.0, 0.78, 0.22, 1.0)

	return Color(0.92, 0.18, 0.15, 1.0)


func _tower_fill_color(placement_service: TowerPlacementService, combat_simulation: CombatSimulation, tower_id: String) -> Color:
	var tower := get_tower_by_id(placement_service, combat_simulation, tower_id)
	if tower == null:
		return Color(0.95, 0.75, 0.30, 1.0)

	match tower.tower_type:
		GameTower.Type.AREA:
			return Color(1.0, 0.52, 0.24, 1.0)
		GameTower.Type.SLOW:
			return Color(0.38, 0.70, 1.0, 1.0)

	return Color(0.95, 0.75, 0.30, 1.0)
