# Design: Road Ribbon Rendering and Asset Contract

## Status

Draft

## Context

The removed semantic road overlay prototype used a small atlas: straight pieces, four turns, and cross. `BoardMapRenderer` chose the tile from neighboring path cells and drew each tile into the grid cell. This kept gameplay aligned, but it still asked generated images to solve hard geometry: exact road width, edge alignment, and turn continuity. Draw padding only hid part of the problem and produced worse visuals than the baked guide workflow.

The active runtime style now uses a full-board baked background generated from a precise path guide. Any future road-ribbon renderer should replace the baked road path for editable maps, not reintroduce semantic road tiles.

## Industry Notes

- Tilemaps remain a standard 2D game representation because a visual grid can share structure with logic data such as collisions and pathfinding; MDN describes tile atlases, map dimensions, visual grids, and logic grids as the common data model: <https://developer.mozilla.org/en-US/docs/Games/Techniques/Tilemaps>.
- Godot TileMap terrains support automatic connection modes (`Connect`, `Path`) plus explicit tile overrides for unresolved cases. This is the same class of solution as autotiling: topology chooses art variants, not manual per-cell art placement: <https://docs.godotengine.org/en/4.0/tutorials/2d/using_tilemaps.html#handling-tile-connections-automatically-using-terrains>.
- Tiled terrain sets make the same separation explicit: tiles are marked by corner/edge/mixed terrain layouts, and the editor adjusts neighbors so transitions connect. Its Patterns view highlights missing patterns, which is the useful lesson for validation here: <https://docs.mapeditor.org/en/latest/manual/terrain/>.
- Unity's 2D Tilemap Extras package includes Rule Tile and custom brushes, another example of selecting sprites from neighbor rules instead of authoring every placement by hand: <https://docs.unity.cn/Manual/com.unity.2d.tilemap.extras.html>.
- Unity Sprite Shape is the alternate industry pattern for roads/paths that should be continuous curves: use a path, angle ranges, and assigned sprites. For this project, the equivalent is a deterministic path/ribbon renderer over the Godot board: <https://docs.unity.cn/Packages/com.unity.2d.spriteshape%406.0/manual/index.html>.
- Godot also has low-level 2D path tools that fit this project-native renderer: `Line2D` supports line width, round joins/caps, texture modes, and antialiasing; `Geometry2D.offset_polyline()` can inflate a centerline into rounded polygons: <https://docs.godotengine.org/en/3.3/classes/class_line2d.html> and <https://docs.godotengine.org/en/stable/classes/class_geometry2d.html#class-geometry2d-method-offset-polyline>.
- OpenAI image masks are useful guidance, but the official image generation guide notes mask following is prompt-based and may not exactly match the mask shape. Therefore masks can help generate source texture, but must not be the final source of geometry truth: <https://platform.openai.com/docs/guides/images/image-generation#edit-an-image-using-a-mask-inpainting>.

## Goals

- Make the visible path wider and smoother at corners without changing gameplay path cells.
- Stop relying on image generation to produce exact road geometry.
- Keep map rendering deterministic, testable, and driven by `level_001.json` path cells.
- Keep generated art useful by limiting it to texture/material inputs that can be clipped, tiled, or sampled by code.
- Provide machine-checkable acceptance criteria for future road assets.

## Non-Goals

- Switching the whole board to Godot `TileMap` immediately.
- Replacing enemy movement; enemies continue to follow the centerline defined by `path_cells`.
- Asking the image model for a perfect complete road atlas as the primary path.

## Proposal

Replace the road overlay atlas path with a `road_ribbon` renderer:

1. Convert `path_cells` to a centerline in board-local coordinates using each cell center.
2. Smooth 90-degree turns by replacing each corner with a quarter arc. The arc radius is style-defined, clamped so it cannot leave the adjacent path cells.
3. Render the road body as a deterministic ribbon around the centerline:
   - `body_width_cells`: default `0.78`.
   - `curb_width_cells`: default `0.10`.
   - `edge_feather_cells`: default `0.03`.
   - `turn_radius_cells`: default `0.36`.
   - joins: round.
   - endpoints: square or round, style-defined.
4. Draw layers in order:
   - background frame.
   - road shadow/ambient edge.
   - curb or border ribbon.
   - paved road body filled by a seamless pavement material.
   - optional edge decoration sprites sampled along the ribbon edge, deterministic by seed.
5. Do not keep the semantic tile renderer as an alternate runtime path.

If road ribbon rendering is introduced, style data should use a structured road block:

```json
{
  "road": {
    "render_mode": "ribbon",
    "body_width_cells": 0.78,
    "curb_width_cells": 0.10,
    "edge_feather_cells": 0.03,
    "turn_radius_cells": 0.36,
    "end_cap": "square",
    "join": "round",
    "seed": 1001,
    "materials": {
      "pavement": "res://assets/tilesets/stormwind_city_v3/road_pavement_seamless.png",
      "curb": "res://assets/tilesets/stormwind_city_v3/road_curb_seamless.png",
      "edge_decals": "res://assets/tilesets/stormwind_city_v3/road_edge_decals.png"
    }
  }
}
```

## Image Generation Contract

Image generation should no longer create road topology. It should create only these source assets:

- `road_pavement_seamless.png`: square seamless material, no perspective road shape, no border, no alpha-critical silhouette.
- `road_curb_seamless.png`: square or strip material used by the renderer for the curb layer.
- `road_edge_decals.png`: transparent decorative sprites such as weeds, small flowers, cracks, and stones, extracted by deterministic postprocessing.
- optional `style_reference.png`: a non-runtime mood image used only to preserve material language.

The prompt should be generated from the JSON contract, not hand-written each time. The prompt must explicitly state:

- "Draw material texture only, not a road, not a path, not a turn."
- "Seamless tileable top-down stone paving."
- "No perspective bend, no junction, no border, no text, no watermark."
- "Camera: top-down / slightly 3/4 top-down consistent with the board background."
- "Output is source material; final road width and shape will be clipped by engine geometry."

The deterministic processor owns the hard rules:

- Crop or resize to the required dimensions.
- Force alpha from generated masks where alpha is needed.
- Tile-check opposite edges for seam similarity.
- Reject assets that contain obvious road topology instead of material.
- Emit a preview with the generated material clipped into the real `level_001` path.

This makes prompt failures cheaper: if the image drifts, we regenerate a material, not a whole road atlas. The renderer still guarantees width, corner radius, and connectivity.

## Validation

Add tests/tools before replacing the runtime renderer:

- Unit test centerline extraction from `path_cells`.
- Unit test corner smoothing for the current route: the two 90-degree turns produce arc points with monotonic directions and stay within board bounds.
- Unit test ribbon config parsing and clamping.
- Pixel/geometry test that sampled road body width is within tolerance at straight segments and turn centers.
- Preview generator that writes `road_ribbon_preview.png` for the active level/style.
- Asset validator for generated materials:
  - dimensions match contract.
  - pavement is opaque.
  - edge decal sheet has alpha.
  - seamless material edge delta is below threshold.
  - no generated asset is required to define the road silhouette.

## Alternatives

- Complete autotile atlas: use 16/47 neighbor-mask road tiles, validate every edge, and optionally use Godot terrain sets. This is a proven tilemap path, but for this project's smooth wide road it still requires the model or an artist to produce many exact turn/intersection shapes.
- Keep the 7-tile semantic atlas and keep tuning padding. This is simple, but it cannot guarantee smooth turns because the tile alpha shape remains uncontrolled.
- Generate one full-board baked road image. This can look good once, but it breaks the grid-aligned contract and makes future path changes expensive.

## Implementation Plan

1. Add `RoadStyleDefinition` parsing for the structured `road` block.
2. Add `RoadRibbonBuilder` in `game/scripts/core/maps/` with pure geometry methods.
3. Add GUT tests for centerline, arcs, clamping, and ribbon dimensions.
4. Add `BoardMapRenderer.draw_road_ribbon()` without preserving the removed tile mode.
5. Add `game/tools/render-road-preview.py` or a Godot headless helper to export a preview.
6. Generate or reuse pavement/curb/decal source materials, then validate them with the preview tool.
7. Remove any temporary preview-only road material assets after the ribbon renderer ships.

## Risks

- Godot `draw_polygon` texture fill may require extra UV handling for good tiling. If this becomes awkward, bake the road ribbon to an image at load time and draw that single texture.
- Overly smooth turns can visually leave the one-cell path footprint. Clamp radius and add geometry tests.
- Curb decoration can become noisy. Keep edge decals optional and seed-deterministic.

## Open Questions

- Should road endpoints be square city-gate cuts or round caps?
- Should the road body be textured by repeated UVs in Godot or baked by a tool into one overlay image?
- Do we need intersections soon, or can the first renderer cover only simple non-branching paths?
