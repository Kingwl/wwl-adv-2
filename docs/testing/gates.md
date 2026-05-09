# Testing Gates

Use these gates as the project-level quality contract for agents and humans.

## Required Commands

For most code changes:

```bash
cd game
./tools/check-all.sh
```

GitHub Actions runs the same project gate in `.github/workflows/ci.yml`.

CI uploads the full `check-all.log` as the `godot-check-logs` artifact on every run, including failed runs.

`check-all.sh` includes JSON/schema validation for `game/data/levels` and `game/data/map_styles`.

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
