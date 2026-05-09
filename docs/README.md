# Docs

This directory stores project documentation that should stay close to the code.

## Agent Reading Order

1. `status.md`: current state, open decisions, verified commands, and known risks.
2. `designs/README.md`: design status index.
3. Relevant design documents under `designs/`.
4. `testing/gates.md`: verification expectations for the change.
5. `todo/backlog.md` and `tech-debt/register.md` for follow-up work.

## Structure

| Path | Purpose |
| --- | --- |
| `status.md` | One-page current project state for agents and humans. |
| `designs/` | Design proposals, architecture notes, and decision records. |
| `milestone/` | Roadmap, delivery plans, and progress checkpoints. |
| `todo/` | Active work items, backlog notes, and short-lived follow-ups. |
| `testing/` | Testing policy, gates, and coverage checklists. |
| `tech-debt/` | Known technical debt, cleanup plans, and risk tracking. |

## Maintenance

- Keep `status.md` current when milestone state, open decisions, verified commands, or major risks change.
- Update `designs/README.md` whenever a design is added or its status changes.
- Put durable testing expectations in `testing/`, not `todo/`.
- Move completed todo items into the relevant milestone, design, or status document when useful.
