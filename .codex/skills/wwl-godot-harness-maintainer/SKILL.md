---
name: wwl-godot-harness-maintainer
description: Use when changing this WWL Godot repo's agent harness, CI workflows, GitHub Pages export pipeline, validation scripts, asset checks, project skills, test gates, or documentation maps.
metadata:
  short-description: WWL harness, CI, and skill maintenance workflow
---

# WWL Harness Maintainer

Use this skill for infrastructure that helps agents and humans validate the project.

## First Reads

1. Read `AGENTS.md`.
2. Read `docs/status.md`.
3. Read `docs/testing/gates.md`.
4. For harness backlog work, read `docs/todo/harness-engineering-todo.md`.
5. For UI/playability validation work, read `docs/designs/2026-05-09-ui-playability-validation.md`.

## Harness Rules

- Keep executable checks in `game/tools/` so humans, agents, and CI share the same commands.
- Keep generated artifacts outside `game/`; use `ci-artifacts/` or `build/`.
- Make shell tools portable: support `GODOT_BIN`, fail loudly, and avoid machine-local assumptions.
- CI should call repo scripts instead of duplicating logic inline.
- CI should upload logs, reports, and screenshots when failures are likely to need agent inspection.
- When adding durable policy, update `docs/testing/`; when adding open follow-up work, update `docs/todo/harness-engineering-todo.md`.
- When changing project state, update `docs/status.md`.

## Project Skills

Project skills live under `.codex/skills/<skill-name>/SKILL.md`.

When adding or changing a skill:

- Keep `SKILL.md` short and procedural.
- Put only trigger-worthy workflow in the skill; keep long project state in docs.
- Do not duplicate shell script internals in the skill.
- Update `AGENTS.md` so agents can discover the project skills.
- If the skill needs to be active in a local Codex install, link or copy it into `$CODEX_HOME/skills` after the versioned file is committed.

## Verification

For docs-only harness changes:

```bash
cd game
./tools/check-docs.sh
```

For script, CI, asset, or test gate changes:

```bash
cd game
./tools/check-all.sh
```

For UI smoke, scene validation, or agent feedback loop changes:

```bash
cd game
./tools/agent-preflight.sh
```

For Web export or Pages changes:

```bash
cd game
./tools/export-web.sh ../build/web
```

Do not claim a CI or Pages change is verified remotely unless the GitHub run has actually completed.
