# Project Status

## Current Milestone

Milestone 1 - Playable Prototype completion, with Milestone 2 MVP preparation underway.

The playable loop is mostly present. The main remaining Prototype decision is the tower progression model: scene-level merge interaction versus direct upgrade.

## Verified Commands

Last checked: 2026-05-09.

```bash
cd game
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
```

Current known test state:

- Godot: 4.6.2 stable.
- GUT: 9.6.0.
- GUT suite: 124 tests passing, 670 assertions.
- Known warning: GUT exits with an ObjectDB leaked instances warning from scene/resource cleanup.

## Implemented

- Godot 4.x project skeleton and GUT setup.
- Testable `game/scripts/core/` rule layer.
- Board placement, removal, reserved slot, and path validation rules.
- Economy wallet, placement cost, kill rewards, and wave clear rewards.
- Enemy path movement, health, death events, and leak handling.
- Fixed tick combat simulation.
- Tower config, registry, targeting, attack cooldown, projectile spawning, projectile movement, and hit detection.
- Wave spawning and wave clear events.
- Player life, victory, and failure state.
- Start scene, main scene, pause menu, restart, return-to-start, win, and lose flows.
- Three basic tower types: Single, Area, and Slow.
- Data-driven level path/style loading for the current map.
- Generated city defense map, road guide artifacts, UI frames, tower sprites, enemy sprites, and attack effects.

## Open Decisions

- Prototype tower progression model: merge interaction or direct upgrade.
- Data shape for tower, enemy, and wave configuration.
- Whether retained completed/defeated enemies need cleanup before longer waves.
- Whether generated road ribbon assets should become deterministic runtime/editor-generated content.

## Known Risks

- `game/scripts/board/board_view.gd` is large and mixes input, layout, rendering, resource loading, HUD state, and simulation integration.
- Tower and wave values are still partly hardcoded in GDScript.
- Test quality relies on GUT plus checklists rather than line coverage.
- Scene tests currently emit an ObjectDB leak warning.
- GitHub Pages currently publishes a static project page, not a playable Godot Web export.

## GitHub Automation

- CI workflow: `.github/workflows/ci.yml`.
- GitHub Pages workflow: `.github/workflows/pages.yml`.
- Pages source: GitHub Actions workflow deployment from `site/`.

## Next Best Work

1. Decide and implement the Prototype tower progression model.
2. Move tower, enemy, and wave definitions toward data files.
3. Split `BoardView` responsibilities after the next gameplay decision.
4. Keep `game/tools/check-all.sh` as the default verification command.
