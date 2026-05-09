# Project Status

## Current Milestone

Milestone 1 - Playable Prototype completion, with Milestone 2 MVP preparation underway.

The playable loop is mostly present. The main remaining Prototype decision is the tower progression model: scene-level merge interaction versus direct upgrade.

## Verified Commands

Last checked: 2026-05-10.

```bash
cd game
./tools/check-all.sh
./tools/agent-preflight.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-ui-smoke.sh
```

Current known test state:

- Godot: 4.6.2 stable.
- GUT: 9.6.0.
- GUT suite: 124 tests passing, 670 assertions.
- Native UI smoke: desktop, mobile landscape, and square viewports passing with screenshots under `ci-artifacts/ui-smoke/native/`.
- Agent preflight: runs `check-all.sh`, native UI smoke, and the UI smoke summary.
- Known warning: GUT exits with an ObjectDB leaked instances warning from scene/resource cleanup. Tracked as TD-007.

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
- Native UI smoke for start-to-main playability, responsive viewports, one tower placement, and screenshot artifacts.
- Agent preflight and UI smoke summary scripts for local agent iteration feedback.
- Project Codex skills for core gameplay rules, scene/UI validation, and harness maintenance.

## Open Decisions

- Prototype tower progression model: merge interaction or direct upgrade.
- Data shape for tower, enemy, and wave configuration.
- Whether retained completed/defeated enemies need cleanup before longer waves.
- Whether generated road ribbon assets should become deterministic runtime/editor-generated content.

## Known Risks

- `game/scripts/board/board_view.gd` is large and mixes input, layout, rendering, resource loading, HUD state, and simulation integration.
- Tower and wave values are still partly hardcoded in GDScript.
- Test quality relies on GUT plus checklists rather than line coverage.
- Scene tests currently emit an ObjectDB leak warning, tracked as TD-007.
- GitHub Pages publishes the static project page and a playable Godot Web export at `/play/`.

## GitHub Automation

- CI workflow: `.github/workflows/ci.yml`.
- CI runs `check-all.sh` plus native UI smoke.
- CI uploads `ci-artifacts/` as the `godot-check-artifacts` artifact.
- GitHub Pages workflow: `.github/workflows/pages.yml`.
- Pages source: GitHub Actions workflow deployment from `site/` plus a Godot Web export under `_site/play/`.
- Local Web export output defaults to `build/web/`, outside the Godot project directory.
- Project skills are versioned under `.codex/skills/`; link them into `$CODEX_HOME/skills` when the local Codex runtime does not auto-load repo-local skills.

## Next Best Work

1. Decide and implement the Prototype tower progression model.
2. Move tower, enemy, and wave definitions toward data files.
3. Split `BoardView` responsibilities after the next gameplay decision.
4. Keep `game/tools/check-all.sh` as the default verification command.
