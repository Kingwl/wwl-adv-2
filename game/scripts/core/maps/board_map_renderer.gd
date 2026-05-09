class_name BoardMapRenderer
extends RefCounted

var _texture_cache: Dictionary
var _canvas_texture_cache: Dictionary


func _init() -> void:
	_texture_cache = {}
	_canvas_texture_cache = {}


func load_style(style: MapStyleDefinition) -> void:
	_texture_cache = {}
	_canvas_texture_cache = {}
	if style == null:
		return

	for path in style.get_all_tile_paths():
		if String(path).is_empty() or _texture_cache.has(path):
			continue

		_texture_cache[path] = load(path) as Texture2D


func draw_board(
	canvas: CanvasItem,
	board: Board,
	style: MapStyleDefinition,
	board_origin: Vector2,
	cell_size: float
) -> void:
	if canvas == null or board == null or style == null:
		return

	var board_rect := Rect2(
		board_origin,
		Vector2(float(board.width) * cell_size, float(board.height) * cell_size)
	)
	_draw_tile(canvas, board_rect, _background_texture_for_style(style))

	for y in range(board.height):
		for x in range(board.width):
			var position := Vector2i(x, y)
			var slot := board.get_slot(position)
			var tile_path := style.get_slot_tile_path(slot.slot_type)
			if tile_path.is_empty():
				continue

			_draw_tile(
				canvas,
				get_slot_draw_rect(position, board_origin, cell_size),
				_texture_for_path(tile_path)
			)


func get_slot_draw_rect(
	position: Vector2i,
	board_origin: Vector2,
	cell_size: float
) -> Rect2:
	return Rect2(
		board_origin + Vector2(float(position.x) * cell_size, float(position.y) * cell_size),
		Vector2(cell_size, cell_size)
	)


func has_texture(resource_path: String) -> bool:
	return _texture_cache.has(resource_path) and _texture_cache[resource_path] != null


func _texture_for_path(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null

	return _texture_cache.get(resource_path, null) as Texture2D


func _background_texture_for_style(style: MapStyleDefinition) -> Texture2D:
	if style == null:
		return null

	var diffuse_texture := _texture_for_path(style.background_tile_path)
	if diffuse_texture == null or style.background_normal_tile_path.is_empty():
		return diffuse_texture

	var normal_texture := _texture_for_path(style.background_normal_tile_path)
	if normal_texture == null:
		return diffuse_texture

	var cache_key := "%s|%s" % [style.background_tile_path, style.background_normal_tile_path]
	if _canvas_texture_cache.has(cache_key):
		return _canvas_texture_cache[cache_key] as Texture2D

	var canvas_texture := CanvasTexture.new()
	canvas_texture.diffuse_texture = diffuse_texture
	canvas_texture.normal_texture = normal_texture
	_canvas_texture_cache[cache_key] = canvas_texture
	return canvas_texture


func _draw_tile(canvas: CanvasItem, rect: Rect2, texture: Texture2D) -> void:
	if texture != null:
		canvas.draw_texture_rect(texture, rect, false)
