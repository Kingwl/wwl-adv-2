# WWL Advanced 2D Tower Merge

Godot 4.x project for a 2D tower defense merge game.

## Layout

- `project.godot`: Godot project file.
- `scenes/`: Godot scenes.
- `scripts/`: Godot scene scripts and testable GDScript gameplay rules.
- `scripts/core/`: deterministic gameplay rules kept separate from scene nodes.
- `assets/`: art, audio, fonts, and other imported game assets.
- `addons/gut/`: GUT test framework.
- `test/gut/`: GUT unit and integration tests.
- `test/godot/`: broader Godot integration test notes.
- `tools/`: local development scripts.

## Current Bootstrap Commands

```bash
./tools/check-all.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-docs.sh
```

Godot scene startup uses `/Applications/Godot.app/Contents/MacOS/Godot` by default. Override it with `GODOT_BIN=/path/to/Godot`.

## Testing Policy

This project uses GDScript-first development with GUT. Keep gameplay rules in `scripts/core/` so they can be tested without depending on active scenes, real frame timing, or UI state.

Use `./tools/check-all.sh` as the default verification command for substantive changes.
