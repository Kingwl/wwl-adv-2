# Design: Grid-Aligned Map Pipeline

## Status

Accepted

## Problem

The previous baked background was a free-form illustration. It used the requested city-defense mood, but its painted road did not share the exact grid contract used by gameplay. Scaling or tinting the image can align one area, but other road segments drift because the painted route is not constrained to cell boundaries.

## Decision

`Board` owns the only gameplay path definition. Runtime map art must be generated from data:

- `res://data/levels/*.json` defines board size, path cells, blocked cells, locked cells, spawn, exit, and `style_id`.
- `res://data/map_styles/*.json` maps a `style_id` to a generated background frame and optional special-cell overlay assets.
- `BoardMapRenderer` draws the generated background frame against the board rect.

The active map style uses a path-guide generated background. The visible road is baked into that background from `path_cells`; enemy movement and tower placement still use the level data as the source of truth.

## Current Path Contract

```text
(0,3) -> (1,3) -> (2,3) -> (3,3) -> (4,3)
                                      |
                                    (4,4) -> (5,4) -> (6,4) -> (7,4) -> (8,4) -> (9,4)
```

## Rendering Rules

- Draw the generated full-board background frame first.
- For normal buildable cells, let the background show through instead of repeating decorative ground tiles.
- Do not draw semantic road overlay tiles or substitute color rectangles.
- Optional blocked and locked overlays may be drawn only when explicit assets are configured.
- Do not draw permanent grid lines in normal play.
- Draw hover, invalid placement, towers, enemies, projectiles, and health bars above the map.

## Validation

The level JSON must match:

- `BoardView.board.width`
- `BoardView.board.height`
- `BoardView.get_default_path()`
- `BoardView.get_map_style_definition().id`

This prevents future map art from silently drifting away from gameplay.

## Current Prototype

- Level: `res://data/levels/level_001.json`
- Style: `res://data/map_styles/stormwind_city_v3.json`
- Tileset: `res://assets/tilesets/stormwind_city_v3/`

This prototype validates the path-guide baked pipeline. Later polish should regenerate the background from the guide or move to deterministic road-ribbon rendering without changing the gameplay contract.
