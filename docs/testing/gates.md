# Testing Gates

Use these gates as the project-level quality contract for agents and humans.

## Required Commands

For most code changes:

```bash
cd game
./tools/check-all.sh
```

For agent preflight before handing off a non-trivial change:

```bash
cd game
./tools/agent-preflight.sh
```

GitHub Actions runs this project gate in `.github/workflows/ci.yml`, then runs the native UI smoke gate.

CI uploads the full `ci-artifacts/` directory as the `godot-check-artifacts` artifact on every run, including failed runs.

`check-all.sh` includes JSON/schema validation for `game/data/levels` and `game/data/map_styles`.

For native UI/playability smoke checks:

```bash
cd game
./tools/check-ui-smoke.sh
```

This runs the Godot desktop/native runtime without Web export, validates the start-to-main scene flow across desktop, mobile landscape, and square viewports, places one tower through the scene input path, and writes screenshots plus `report.json` under `ci-artifacts/ui-smoke/native/`.

Use `./tools/summarize-ui-smoke.py` to reprint the latest smoke report without rerunning Godot.

For documentation-only changes:

```bash
cd game
./tools/check-docs.sh
```

## Gameplay Rule Changes

Any change to merge, combat, waves, economy, placement, targeting, enemy movement, enemy health, player life, or victory/failure rules must include a focused GUT test.

Tests should assert both success and failure or edge behavior when the rule has structured failure outcomes.

## Scene And UI Changes

Scene/UI changes should keep rule assertions in core tests. Scene tests should cover integration boundaries:

- Scene loads.
- Required nodes exist.
- Resources load.
- UI state reflects core state.
- Input reaches the correct core service.
- Pause, restart, win, and lose flows preserve gameplay state.

Run `./tools/check-ui-smoke.sh` for scene, layout, rendering, input, or UI asset changes, then inspect the summary and screenshots before continuing. It is a smoke test, not a pixel-perfect visual regression test.

## Bug Fixes

Bug fixes should add a regression test that fails before the fix and passes after it.

If a regression is visual-only and hard to assert in GUT, record the manual verification in the final response and add a follow-up in `docs/todo/backlog.md`.

## Documentation Changes

When documentation layout changes:

- Update `docs/README.md`.
- Update `docs/status.md` when project state changes.
- Update `docs/designs/README.md` when design status changes.
- Run `./tools/check-docs.sh`.

## GitHub Pages

GitHub Pages is deployed by `.github/workflows/pages.yml` from the static files in `site/` plus a Godot Web export under `_site/play/`.

Local Web export output must stay outside the Godot project directory. Use:

```bash
cd game
./tools/export-web.sh ../build/web
```

The script rejects output paths inside `game/`.
