# Testing

This directory contains durable testing policy and project gates.

## Files

- `checklist.md`: feature-level checklist for rule, scene, and manual testing.
- `gates.md`: required verification gates for code and documentation changes.
- `prototype-rule-coverage.md`: current Prototype rule coverage map.

## Commands

Prefer the aggregate command:

```bash
cd game
./tools/check-all.sh
```

For documentation-only changes:

```bash
cd game
./tools/check-docs.sh
```
