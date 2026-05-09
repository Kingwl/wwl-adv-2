---
name: wwl-godot-scene-harness
description: Use when developing, modifying, or validating scenes, UI, layouts, BoardView behavior, input routing, rendered screenshots, or native playability smoke tests in the WWL Advanced 2D Tower Merge Godot repo.
metadata:
  short-description: WWL Godot scene and UI validation workflow
---

# WWL Godot Scene Harness

Use this skill for scene/UI work in `/Users/bytedance/opensource/wwl-adv-2`.

## First Reads

1. Read `AGENTS.md`.
2. Read `docs/status.md`.
3. Read `docs/testing/gates.md`.
4. For scene validation work, read `docs/designs/2026-05-09-ui-playability-validation.md`.
5. If the user names a scene or feature, find matching files with `rg --files game/scenes game/scripts game/test/gut`.

## Scene Development Rules

- Treat scene scripts as adapters for rendering, input, signals, resource loading, and state sync.
- Keep gameplay rules in `game/scripts/core/`; do not add rule-heavy logic to `BoardView`.
- When changing a scene contract, update or add GUT scene tests under `game/test/gut/scenes/`.
- When changing UI layout, verify at desktop, mobile-landscape, and square/compact viewports.
- Keep local Web export output outside `game/`.

## Scene Verification

For native UI/playability smoke:

```bash
cd game
./tools/check-ui-smoke.sh
```

For a narrower viewport debug run:

```bash
cd game
UI_SMOKE_VIEWPORTS=1280x720 ./tools/check-ui-smoke.sh
```

To reprint the latest report:

```bash
cd game
./tools/summarize-ui-smoke.py
```

Before handoff:

```bash
cd game
./tools/agent-preflight.sh
```

## Coverage Boundary

The current native smoke runner covers the start-to-main playable path:

- `res://scenes/start.tscn`
- `res://scenes/main.tscn`
- one tower placement through the scene input path
- screenshot checks for desktop, mobile-landscape, and square viewports

If the user asks to test another scene, do not imply it is covered by the current smoke runner. Either add a GUT scene test, extend `game/tools/ui_smoke_runner.gd` with an explicit scene contract, or clearly report that only manual/local verification was performed.

## Failure Triage

Inspect these artifacts before deciding what failed:

- `ci-artifacts/ui-smoke/native/report.json`
- `ci-artifacts/ui-smoke/native/report.md`
- `ci-artifacts/ui-smoke/native/godot.log`
- `ci-artifacts/ui-smoke/native/*.png`

Classify failures as scene load, missing node, layout bounds, input routing, gameplay state, blank render, or Godot runtime error. Fix the narrowest layer that owns the failure.
