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
./tools/check-assets.sh
./tools/export-web.sh ../build/web
```

Godot scene startup uses `/Applications/Godot.app/Contents/MacOS/Godot` by default. Override it with `GODOT_BIN=/path/to/Godot`.

## Testing Policy

This project uses GDScript-first development with GUT. Keep gameplay rules in `scripts/core/` so they can be tested without depending on active scenes, real frame timing, or UI state.

Use `./tools/check-all.sh` as the default verification command for substantive changes.

## Web Export

The Web export preset is stored in `export_presets.cfg`. Local Web export output must stay outside the Godot project directory:

```bash
./tools/export-web.sh ../build/web
```

The script refuses paths inside `game/` to avoid imported export artifacts affecting the Godot project. GitHub Pages exports to `_site/play/` in CI.

The Web preset excludes GUT, tests, tools, raw/generated art sources, map pipeline contracts, schema files, and other non-runtime metadata to keep `index.pck` focused on playable assets. The remaining size floor is mostly the Godot Web runtime `index.wasm`.
