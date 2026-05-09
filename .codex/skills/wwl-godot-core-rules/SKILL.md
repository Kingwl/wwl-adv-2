---
name: wwl-godot-core-rules
description: Use when changing deterministic gameplay rules in the WWL Advanced 2D Tower Merge Godot repo, including board placement, merge behavior, towers, targeting, combat, projectiles, economy, waves, enemies, player life, victory or failure state, and data-driven rule behavior.
metadata:
  short-description: WWL Godot core gameplay rule workflow
---

# WWL Godot Core Rules

Use this skill for gameplay rule work in `/Users/bytedance/opensource/wwl-adv-2`.

## First Reads

1. Read `AGENTS.md`.
2. Read `docs/status.md`.
3. Read the relevant design under `docs/designs/` when the change touches an existing decision.
4. Read `docs/testing/gates.md` before choosing the verification command.

## Development Rules

- Keep deterministic gameplay logic in `game/scripts/core/`.
- Keep scene nodes, HUD labels, input coordinates, rendering, and frame timing out of core rule services.
- Prefer `RefCounted` rule/service classes for core logic unless the local pattern requires otherwise.
- Add or update focused GUT tests before changing merge, combat, wave, economy, placement, targeting, enemy movement, player life, or win/loss rules.
- Test both success and structured failure paths when the rule returns a result object.
- If a rule change affects the playable scene state, update the scene adapter after the core tests are passing.

## Usual File Targets

- Core code: `game/scripts/core/<domain>/`.
- Rule tests: `game/test/gut/<domain>/`.
- Scene adapter only when needed: `game/scripts/board/board_view.gd`.
- Data/schema changes: `game/data/`, `game/tools/check-assets.sh`, and related schemas.

## Verification

For focused rule iteration:

```bash
cd game
./tools/test-gut.sh
```

For substantive changes:

```bash
cd game
./tools/check-all.sh
```

If the rule change affects UI state, placement input, rendering, or scene flow:

```bash
cd game
./tools/check-ui-smoke.sh
```

Before handing off a non-trivial change:

```bash
cd game
./tools/agent-preflight.sh
```

Report which tests were added or changed, which commands ran, and any known warning such as TD-007.
