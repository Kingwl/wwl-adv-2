# Harness Engineering Todo

This backlog tracks project infrastructure work inspired by OpenAI's Harness Engineering guidance:

https://openai.com/zh-Hans-CN/index/harness-engineering/

Use this document for harness follow-ups that make the project easier for agents to inspect, validate, and safely change. When an item becomes durable policy, move it into `docs/testing/` or `docs/designs/`.

## P0 - Next Harness Work

- [x] Add a native UI smoke test gate for development-time playability.
  - Design: `docs/designs/2026-05-09-ui-playability-validation.md`.
  - Run the Godot project directly without Web export.
  - Cover desktop, mobile landscape, and square/compact viewports.
  - Start from the start scene, enter the main scene, place one tower, and capture screenshots.
  - Upload screenshot, Godot log, and report artifacts in CI.

- [ ] Add a Web export smoke gate for publish confidence.
  - Reuse the same design: `docs/designs/2026-05-09-ui-playability-validation.md`.
  - Export to a directory outside `game/`.
  - Serve the export over local HTTP.
  - Open the page with a browser runner.
  - Assert the canvas exists, is nonblank, and has no critical console errors.
  - Treat this as an export/Pages gate, not the default local debugging loop.

- [ ] Add structural lint for Godot architecture boundaries.
  - Keep `game/scripts/core/` independent from scene/UI nodes.
  - Flag new gameplay rule logic added directly to `BoardView`.
  - Track `BoardView` size/coupling so it cannot keep growing unnoticed.
  - Report violations as a clear CI failure.

- [ ] Add deterministic gameplay replay evals.
  - Use fixed seeds and scripted player actions.
  - Produce a machine-readable result summary with wave state, lives, gold, leaks, victory/defeat, and elapsed ticks.
  - Compare replay output against expected snapshots.

## P1 - Stronger Agent Feedback

- [ ] Parse Godot and GUT logs into `report.json` and `report.md`.
  - Classify errors, warnings, test failures, and known warnings such as TD-007.
  - Upload parsed reports as CI artifacts.

- [ ] Move tower, enemy, and wave configuration into data files with schema checks.
  - Extend `check-assets.sh` beyond level and map style definitions.
  - Validate references between data files and runtime assets.

- [x] Add an agent preflight command.
  - Run the standard local gates.
  - Summarize changed files, generated artifacts, and known warnings.
  - Print the Pages playable URL when relevant.

- [x] Add project Codex skills for specialized agent workflows.
  - Core gameplay rule development.
  - Scene/UI playability validation.
  - Harness, CI, Pages, asset checks, and skill maintenance.

## P2 - Later

- [ ] Add lightweight visual regression coverage for important viewports.
  - Capture desktop and mobile landscape screenshots.
  - Compare against approved baselines or at least keep them as CI artifacts.

- [ ] Revisit GitHub branch protection and required CI when collaboration expands beyond solo development.

- [ ] Investigate Godot Web runtime size only if download size becomes a product issue.
  - Current main size floor is the Godot Web runtime `index.wasm`.
  - Prefer asset and export-preset cleanup before custom engine-template work.
