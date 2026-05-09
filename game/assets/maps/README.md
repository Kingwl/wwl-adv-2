# Maps

## Current Runtime Pipeline

The active game board uses a path-guide generated baked background. Runtime map rendering is data-driven by the level and style files:

- Level data: `res://data/levels/level_001.json`
- Style data: `res://data/map_styles/stormwind_city_v3.json`
- Generated map assets: `res://assets/tilesets/stormwind_city_v3/`

`BoardMapRenderer` draws one generated full-board background frame. The visible road is baked into that background from the same `path_cells` that drive enemy movement and placement restrictions; semantic road overlay assets are no longer part of the runtime path.

## `stormwind_inspired_city_defense_aligned`

Legacy aligned background generated from the previous `BoardView` grid contract, using an image-generated Stormwind-inspired high-fantasy city style source.

Files:

- `stormwind_inspired_city_defense_aligned.png`: 1280x1024 runtime board image.
- `stormwind_inspired_city_defense_aligned.style_source.png`: image-generated visual style source.
- `stormwind_inspired_city_defense_aligned.prompt.txt`: prompt and pipeline notes.
- `res://data/maps/stormwind_inspired_city_defense_aligned.contract.json`: grid, cell, and path contract.

This is retained for reference. The current runtime path uses a path-guide generated full-board raster wired through `stormwind_city_v3`.

## `grid_aligned_city_defense`

Earlier contract-aligned prototype background. It is retained for reference, but no longer wired into `BoardView`.

Files:

- `grid_aligned_city_defense.png`
- `res://data/maps/grid_aligned_city_defense.contract.json`

## `stormwind_inspired_city_defense`

Generated with `generate2dmap` as a baked raster map for the current 10x8 tower-defense board.

Files:

- `stormwind_inspired_city_defense.png`: normalized 1280x1024 runtime map image.
- `stormwind_inspired_city_defense.raw.png`: original generated image copy.
- `stormwind_inspired_city_defense.prompt.txt`: prompt used for generation.

Metadata:

- `res://data/maps/stormwind_inspired_city_defense.manifest.json`
- `res://data/maps/stormwind_inspired_city_defense.collision.json`

The map is an original high-fantasy white-stone human capital defense board with blue-and-gold banners, canals, cathedral spires, and fortified plazas. It is inspired by the requested Stormwind mood, but avoids copying specific layouts, logos, characters, or emblems.
