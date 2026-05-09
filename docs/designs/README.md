# Designs

Use this directory for design proposals, architecture notes, and decision records.

## Status Values

- `Draft`: proposed but not yet accepted.
- `Accepted`: selected direction, not fully implemented.
- `Implemented`: represented in code and tests.
- `Deferred`: useful reference, intentionally paused.
- `Superseded`: replaced by another design.

## Design Index

| Design | Status | Implementation | Notes |
| --- | --- | --- | --- |
| `2026-05-08-godot-2d-tower-defense-merge.md` | Implemented | `game/`, `game/scripts/core/` | Overall product and architecture direction. |
| `2026-05-08-testing-coverage-strategy.md` | Implemented | `game/test/gut/`, `docs/testing/`, `game/tools/` | GUT-first strategy; no line coverage gate yet. |
| `2026-05-08-board-grid-rules.md` | Implemented | `game/scripts/core/board/` | Placement, removal, slot types, path validation. |
| `2026-05-08-board-scene-adapter.md` | Implemented | `game/scripts/board/board_view.gd` | Scene adapter exists; file is now a refactor risk. |
| `2026-05-08-economy-resource-system.md` | Implemented | `game/scripts/core/economy/`, `game/scripts/core/placement/` | Placement cost and rewards are implemented. |
| `2026-05-08-enemy-path-movement.md` | Implemented | `game/scripts/core/movement/`, `game/scripts/core/enemies/` | Deterministic path progress and scene rendering. |
| `2026-05-08-single-enemy-health-death.md` | Implemented | `game/scripts/core/enemies/`, `game/scripts/core/combat/` | Health, damage, death events, rewards. |
| `2026-05-08-fixed-tick-combat-simulation.md` | Implemented | `game/scripts/core/combat/combat_simulation.gd` | Fixed tick combat loop is active. |
| `2026-05-08-projectile-hit-detection.md` | Implemented | `game/scripts/core/combat/projectile_service.gd` | Real projectile movement and hit events. |
| `2026-05-08-tower-types-framework.md` | Implemented | `game/scripts/core/towers/` | Single, Area, Slow tower types. Stats still hardcoded. |
| `2026-05-08-wave-system.md` | Implemented | `game/scripts/core/waves/` | Three current waves; MVP needs more content and data files. |
| `2026-05-08-victory-failure-conditions.md` | Implemented | `game/scripts/core/player/`, `game/scripts/core/combat/` | Lives, leak handling, win/loss outcomes. |
| `2026-05-08-game-flow-ui.md` | Implemented | `game/scenes/`, `game/scripts/board/board_view.gd` | Start, pause, restart, return, win, and lose flows. |
| `2026-05-08-grid-aligned-map-pipeline.md` | Implemented | `game/data/levels/`, `game/data/map_styles/`, assets | Current map follows a grid-aligned contract. |
| `2026-05-09-path-guide-road-generation.md` | Implemented | `game/tools/generate-road-guide.py`, `game/tools/out/` | Guide/mask artifacts are generated from gameplay path data. |
| `2026-05-09-road-ribbon-rendering-and-asset-contract.md` | Accepted | `game/tools/generate-road-guide.py`, map assets | Contract partly proven; deterministic road material generation remains future work. |
| `2026-05-09-merge-ui-integration.md` | Deferred | Core merge only: `game/scripts/core/towers/tower_merge_service.gd` | Blocked by merge versus direct upgrade decision. |

## Tooling Index

| Tooling | Status | Implementation | Notes |
| --- | --- | --- | --- |
| Level and map style schema checks | Implemented | `game/data/schemas/`, `game/tools/check-assets.sh` | Runs inside `check-all.sh`. |
| Godot Web export and Pages playable build | Implemented | `game/export_presets.cfg`, `game/tools/export-web.sh`, `.github/workflows/pages.yml` | Export output is outside `game/`; Pages publishes it under `/play/`. |

## Expectations

Each design document should explain the problem, goals, constraints, proposed solution, alternatives, risks, and open questions.

When implementation changes the design status, update this index and `docs/status.md` if it changes current project state.
