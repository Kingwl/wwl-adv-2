# Design: UI Playability Validation

## Status

Accepted

## Context

The project already has strong GUT coverage for core gameplay rules and scene integration. It also exports a playable Godot Web build to GitHub Pages under `/play/`.

The missing harness layer is automated UI/playability validation. A scene can pass unit tests while still rendering a blank board, breaking layout at a common viewport, failing to route input, or publishing a broken Web export.

Web validation alone is not the right development loop. Web export adds a slow build step and mostly validates export/runtime packaging. Day-to-day debugging should run against the Godot desktop/native runtime first, because it is closer to how the project is edited and much faster to iterate.

This design defines two validation layers:

- Native UI smoke: fast local and CI gate for development. Implemented by `game/tools/check-ui-smoke.sh`.
- Web export smoke: slower publish gate for Web/Pages packaging. Not implemented yet.

## Goals

- Provide a fast native UI smoke command that does not require Web export.
- Exercise real scene flow, viewport layout, basic input, and one gameplay interaction.
- Capture screenshots and machine-readable reports for agent inspection.
- Keep Web smoke focused on export-specific failures: missing resources, browser runtime errors, blank canvas, and Pages packaging.
- Keep all generated artifacts outside `game/`.

## Non-Goals

- Full visual regression testing with strict golden image comparison.
- Balance or strategy validation.
- Long-play endurance testing.
- Custom Godot engine template size optimization.
- Replacing GUT or deterministic core tests.

## Proposal

Add a primary native smoke gate:

```bash
./game/tools/check-ui-smoke.sh
```

The native smoke command should run the Godot project directly, without exporting. It should execute a dedicated GDScript runner under the normal desktop renderer:

```bash
godot --path game --script res://tools/ui_smoke_runner.gd
```

On CI Linux, run it with a virtual display:

```bash
xvfb-run -a godot --path game --script res://tools/ui_smoke_runner.gd
```

The runner should:

1. Create a viewport for each required viewport size.
2. Load `res://scenes/start.tscn`.
3. Verify the title and start button are present.
4. Activate the start flow and verify `res://scenes/main.tscn` loads.
5. Verify the board, HUD, tower deck, wave state, gold, and lives labels exist.
6. Advance enough frames for layout and initial simulation to settle.
7. Place one tower on a known buildable cell through the same input path used by the scene.
8. Advance the simulation briefly and verify the board remains playable.
9. Save screenshots and a report outside `game/`.
10. Exit with a nonzero status on failure.

Required native viewports:

- Desktop: `1280x720`.
- Mobile landscape: `896x414`.
- Square/compact: `720x720`.

Artifacts should be written to `ci-artifacts/ui-smoke/native/`:

- `report.json`: pass/fail, viewport sizes, checks, timings, and failure messages.
- `report.md`: short human-readable summary.
- `desktop.png`.
- `mobile-landscape.png`.
- `square.png`.
- `godot.log`.

The first version should use smoke assertions, not exact pixel matching. It should fail on blank/broken output, missing nodes, impossible placement, or obvious layout collapse.

## Web Export Smoke

Add a secondary Web smoke command:

```bash
./game/tools/check-web-smoke.sh
```

This command should be slower and focused on export/deploy confidence:

1. Export to `build/web-smoke/` using `./game/tools/export-web.sh`.
2. Serve the export over local HTTP.
3. Check HTTP 200 responses for `/`, `/index.wasm`, and `/index.pck`.
4. Open the page with Playwright Chromium.
5. Assert a nonblank canvas and no critical browser errors.
6. Save screenshots, console logs, server logs, and `report.json` under `ci-artifacts/ui-smoke/web/`.

Web smoke should not be the default development debugging path. It should run before publishing or when Web/export tooling changes.

## CI Integration

Add native UI smoke to `.github/workflows/ci.yml` after `./tools/check-all.sh` once the runner is stable.

Upload `ci-artifacts/` even on failure. This keeps native screenshots and reports available to agents.

Keep `.github/workflows/pages.yml` focused on publishing. The Pages workflow may run Web smoke before upload, but native UI failures should be caught earlier in CI.

Suggested staging:

1. Implement `check-ui-smoke.sh` and run it manually/local-first.
2. Add native UI smoke to CI as a required project gate.
3. Add Web smoke to Pages workflow or a separate publish-check job.
4. Only consider putting Web smoke in regular CI if export regressions become common.

## Failure Policy

Native smoke should fail on:

- Scene load failure.
- Missing required UI nodes.
- Blank screenshots or zero-sized viewport content.
- Layout values outside viewport bounds.
- Failure to start from the start scene.
- Failure to place one tower through the scene input path.
- New Godot errors not explicitly allowlisted.

Web smoke should fail on:

- Web export failure.
- HTTP failure for `index.html`, `index.wasm`, or `index.pck`.
- Missing browser canvas.
- Blank canvas area.
- Browser `pageerror`.
- Critical console/runtime errors such as `Uncaught`, `RuntimeError`, `LinkError`, `Failed to fetch`, `404`, or `Cannot load`.

Do not fail either gate on:

- Known Godot warnings already tracked in tech debt.
- Noncritical warnings that do not affect loading or rendering.
- Exact screenshot pixel differences.

Maintain an explicit allowlist for known benign warnings. New warnings should be reviewed before being allowlisted.

## Implementation Shape

Expected native files:

- `game/tools/check-ui-smoke.sh`: shell orchestrator.
- `game/tools/ui_smoke_runner.gd`: Godot runner that loads scenes, drives input, captures screenshots, and writes reports.
- `game/tools/summarize-ui-smoke.py`: report summarizer for agent iteration.
- `game/tools/agent-preflight.sh`: local handoff command that runs project gates, UI smoke, and artifact summaries.
- `docs/testing/gates.md`: mention the native UI smoke gate once implemented.

Expected Web files:

- `game/tools/check-web-smoke.sh`: shell orchestrator for export and local server.
- `tools/web-smoke/package.json`: pinned Playwright dependency, if a scoped Node tool package is chosen.
- `tools/web-smoke/check-web-smoke.mjs`: browser assertions.

Native command overrides:

- `GODOT_BIN`: Godot executable.
- `UI_SMOKE_ARTIFACT_DIR`: default `ci-artifacts/ui-smoke/native`.
- `UI_SMOKE_VIEWPORTS`: optional comma-separated viewport override for debugging.

Web command overrides:

- `GODOT_BIN`: Godot executable.
- `WEB_SMOKE_OUTPUT_DIR`: default `build/web-smoke`.
- `WEB_SMOKE_ARTIFACT_DIR`: default `ci-artifacts/ui-smoke/web`.
- `WEB_SMOKE_PORT`: optional fixed local port for debugging.

## Alternatives

- Only use GUT scene tests: fast and useful, but they do not capture rendered screenshots or real viewport behavior.
- Only use Web smoke: validates publishing, but it is too slow and indirect for development debugging.
- Use strict screenshot baselines immediately: stronger visual signal, but too brittle before the UI stabilizes.
- Run deployed Pages URL only: useful as a post-deploy check, but slower and less actionable than testing local export before deploy.

## Risks

- Native smoke needs a display backend in CI, likely `xvfb-run` on Linux.
- Screenshot checks can be flaky if captured before rendering settles.
- The runner can become another parallel test framework if it grows too broad.
- Playwright adds a Node/browser dependency for Web smoke.
- Console/error allowlists can hide real issues if they are too broad.

## Open Questions

- Should native UI smoke enter `check-all.sh`, or remain a separate command until stable?
- Should native smoke drive input by coordinates, grid helpers, or public scene methods?
- Should Web smoke run in Pages only, or in CI when `game/**` changes?
- Should the native runner eventually include deterministic replay evals, or should replay stay as a separate harness?
