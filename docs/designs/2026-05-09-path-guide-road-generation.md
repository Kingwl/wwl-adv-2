# Design: Path Guide Road Generation

## Status

Accepted.

## Context

The original map road used a small road-tile overlay atlas. That kept gameplay aligned to `path_cells`, but the visual quality depended on generated turn tiles being exactly wide enough and cleanly connected. In practice the corners were too narrow, and draw padding only hid part of the problem.

The current map style uses a better workflow:

1. Generate a precise road guide from gameplay data.
2. Ask image generation to style that guide into a complete board image.
3. Keep gameplay path data unchanged.
4. Integrate the generated result as the runtime baked map style.

This document records that workflow so future map generation is guided by project rules instead of repeated manual prompt tuning.

## Current Implementation

Active level:

- `res://data/levels/level_001.json`
- `style_id`: `stormwind_city_v3`

Generated path-guide style:

- `res://data/map_styles/stormwind_city_v3.json`
- `res://assets/tilesets/stormwind_city_v3/background_frame.png`
- `res://assets/tilesets/stormwind_city_v3/background_frame_normal.png`

The generated road is baked into `background_frame.png`. `BoardMapRenderer` keeps gameplay path slots intact for movement and placement, but it does not draw road overlay tiles on top.

Tooling:

- `game/tools/generate-road-guide.py`
- Default output: `game/tools/out/road_guides/<level_id>/`
- The output directory is ignored by git because generated guide images are review artifacts.

## Pipeline

### 1. Generate The Guide From Gameplay Data

Use `level_001.json` as the source of truth:

- grid size: `10 x 8`
- board image size: `1280 x 1024`
- cell size: `128`
- path cells:

```text
(0,3) -> (1,3) -> (2,3) -> (3,3) -> (4,3)
                                      |
                                    (4,4) -> (5,4) -> (6,4) -> (7,4) -> (8,4) -> (9,4)
```

The guide generator draws:

- road body mask from the path centerline.
- curb mask around the body.
- optional shadow mask.
- a visible guide preview with clear colors:
  - cream road body.
  - blue curb zone.
  - red enemy centerline.

The guide must be produced by code, not by hand. This guarantees the guide matches gameplay `path_cells`.

Current command:

```bash
game/tools/generate-road-guide.py \
  --overlay-image res://assets/tilesets/stormwind_city_v3/background_frame.png
```

Generated files:

- `road_body_mask.png`
- `road_curb_mask.png`
- `road_curb_ring_mask.png`
- `road_shadow_mask.png`
- `road_guide_preview.png`
- `road_guide_annotated.png`
- `game_path_overlay.png`
- `road_guide_manifest.json`

### 2. Generate The Styled Board Image

Use image generation with the guide visible as the layout reference.

Prompt requirements:

- Preserve the exact road route, road width, rounded turns, start edge, and exit edge from the guide.
- Convert the road body into pale warm stone paving.
- Convert the curb zone into raised white-stone borders with small edge decoration.
- Remove guide markings: no red centerline, no blue overlay color, no labels, no dots.
- Do not add extra roads, branches, intersections, UI, text, logos, or characters.
- Keep the same top-down / slightly 3/4 board perspective.

The generated image is treated as a background candidate. It is not allowed to change gameplay data.

### 3. Normalize And Integrate

Normalize the generated image to the board asset size:

```text
1280 x 1024
```

Place it under a new style folder:

```text
game/assets/tilesets/stormwind_city_v3/
├── background_frame.png
└── background_frame_normal.png
```

Create a dedicated style JSON:

```text
game/data/map_styles/stormwind_city_v3.json
```

The style JSON should point at the baked background and normal map only. Path and buildable terrain are part of the background, so the style does not define semantic road tile mappings.

This keeps runtime loading simple while avoiding double-drawn roads and transparent placeholder assets.

### 4. Switch The Level

For the active level, set:

```json
"style_id": "stormwind_city_v3"
```

in:

```text
game/data/levels/level_001.json
```

## Why This Works Better

- The path shape starts from game data, so the generated image has a stronger spatial target.
- The generated result can look hand-painted and cohesive, unlike a small tile atlas with visible repeated pieces.
- Existing gameplay path, tower placement, targeting, and enemy movement do not change.
- The workflow is compatible with a future deterministic road-ribbon renderer. The guide/mask generator can become that renderer's preview/bake tool.

## Validation

Required checks:

- `LevelDefinition.style_id` points to `stormwind_city_v3`.
- `MapStyleDefinition` can load the generated style.
- `BoardMapRenderer` loads the generated background and normal textures.
- Map rendering does not depend on road overlay, transparent placeholder, or semantic tile assets.
- `game/tools/test-gut.sh` passes.

Current validation:

```text
128/128 GUT tests passing
```

## Known Limitations

- The road geometry is visually baked into one image. Changing `path_cells` requires regenerating the guide and image.
- Image generation can still drift from the guide. For production quality, enforce masks or use the deterministic road-ribbon renderer.
- Because the road is part of the background, path tile overlays are disabled. Any future blocked/locked/road overlay polish should account for this style mode.

## Relationship To Road Ribbon Rendering

This is the short-term art workflow for fast evaluation.

The longer-term engineering direction remains:

- Generate road geometry from `path_cells`.
- Fill it with generated pavement/curb materials.
- Validate width and corner radius programmatically.

That direction is documented in:

```text
docs/designs/2026-05-09-road-ribbon-rendering-and-asset-contract.md
```
