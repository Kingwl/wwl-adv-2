# Agents Guide

## First Read

Start with `docs/status.md`. It is the current one-page project state for agents.

Use `docs/README.md` as the documentation map. Do not rely on a hand-maintained full file tree; use `find` or `rg --files` when you need the exact current layout.

## Project Direction

This project is a Godot 2D tower defense merge game. Development should stay test-driven:

- Keep gameplay rules in `game/scripts/core/` instead of embedding them directly in Godot scenes.
- Prefer deterministic simulations with fixed ticks and seeded randomness.
- Add or update GUT tests before changing merge, combat, wave, economy, placement, or targeting rules.
- Use scene tests only for integration boundaries: nodes, resources, UI state sync, scene flow, and Godot-specific wiring.

## Documentation Routes

| Need | Read or update |
| --- | --- |
| Current state, open decisions, verified commands | `docs/status.md` |
| Documentation map | `docs/README.md` |
| Project skills for specialized agents | `.codex/skills/` |
| Architecture decisions and proposals | `docs/designs/` and `docs/designs/README.md` |
| Delivery scope and roadmap | `docs/milestone/` |
| Active work queue | `docs/todo/backlog.md` |
| Harness engineering automation gaps | `docs/todo/harness-engineering-todo.md` |
| Testing policy and gates | `docs/testing/` |
| Risks and cleanup work | `docs/tech-debt/register.md` |

## Documentation Rules

- Add long-lived architecture or gameplay decisions to `docs/designs/` using `docs/designs/template.md`.
- Update `docs/designs/README.md` when adding, deferring, superseding, or implementing a design.
- Update `docs/status.md` when current milestone status, verified commands, open decisions, or major risks change.
- Keep temporary task lists in `docs/todo/`; move durable testing guidance to `docs/testing/`.
- Track agent-facing harness automation follow-ups in `docs/todo/harness-engineering-todo.md` until they become implemented gates or durable testing policy.
- Record cleanup work and engineering risks in `docs/tech-debt/register.md`.

## Project Skills

Project skills are versioned under `.codex/skills/`.

- Use `wwl-godot-core-rules` for deterministic gameplay rule work under `game/scripts/core/`.
- Use `wwl-godot-scene-harness` for scene, UI, layout, input, screenshot, or playability validation work.
- Use `wwl-godot-harness-maintainer` for CI, GitHub Pages, validation scripts, asset checks, docs gates, or project skill maintenance.

If the current Codex runtime does not auto-load repo-local skills, treat those files as the canonical workflow references and optionally link them into `$CODEX_HOME/skills` for local use.

## Project Layout

```text
.codex/
└── skills/
game/
├── project.godot
├── addons/gut/
├── scenes/
├── scripts/
│   ├── board/
│   ├── core/
│   └── ui/
├── data/
├── assets/
├── test/
└── tools/
```

## Verification

For substantive changes, run:

```bash
cd game
./tools/check-all.sh
```

For agent iteration before handing off a non-trivial change, run:

```bash
cd game
./tools/agent-preflight.sh
```

For scene, layout, rendering, input, or UI asset changes, run `./tools/check-ui-smoke.sh` and inspect the printed summary plus screenshots under `../ci-artifacts/ui-smoke/native/`. Treat this as part of the agent feedback loop, not only as a CI check.

Individual checks:

```bash
cd game
./tools/agent-preflight.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-docs.sh
./tools/check-assets.sh
./tools/check-ui-smoke.sh
./tools/summarize-ui-smoke.py
./tools/export-web.sh ../build/web
```

If a check cannot be run, note the reason in the final response.
