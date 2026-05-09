# Milestone Plan

Current project state is summarized in `docs/status.md`. Keep this file as the historical Milestone 0 bootstrap checkpoint instead of a second live status source.

## Current Milestone

- Name: Milestone 0 - Project Bootstrap
- Status: Complete
- Target date: TBD
- Owner: TBD

## Scope

- Create the Godot 4.x GDScript project.
- Build a testable `scripts/core/` rule layer.
- Add GUT tests and Godot headless checks.
- Pick one Godot scene testing plugin.

## Completion Criteria

- Command line can run GUT tests.
- Godot project can start in headless mode.
- First TDD flow is complete: failing merge-rule test, implementation, passing test.

## Risks

- Godot scene logic may leak into core rules and reduce testability.
- GDScript-only implementation would make strict code coverage harder.
- Test discipline must be enforced through rule coverage checklists and regression tests.

## Progress

- [x] Documented gameplay direction and testing strategy.
- [x] Create Godot project skeleton.
- [x] Add GUT test project.
- [x] Run Godot headless startup check.
- [x] Run first core unit tests.
- [x] Add Godot scene test plugin.
- [x] Switch project direction to GDScript-first.
