# MMO v1 Sprite Assets

This pack contains original high-fantasy MMO style assets for the tower-defense prototype. The visual direction borrows broad Warcraft-like fantasy archetypes, but avoids exact World of Warcraft units, buildings, logos, named creatures, or recognizable silhouettes.

## Towers

All tower frames are 128x128 transparent PNGs.

- `towers/single_tower.png`: static human kingdom ballista guard tower.
- `towers/single_tower_attack_1.png` ... `single_tower_attack_4.png`
- `towers/single_tower_attack_strip.png`: 4-frame horizontal strip.
- `towers/area_tower.png`: static dwarven-style siege mortar tower.
- `towers/area_tower_attack_1.png` ... `area_tower_attack_4.png`
- `towers/area_tower_attack_strip.png`: 4-frame horizontal strip.
- `towers/slow_tower.png`: static frost crystal spire tower.
- `towers/slow_tower_attack_1.png` ... `slow_tower_attack_4.png`
- `towers/slow_tower_attack_strip.png`: 4-frame horizontal strip.

## Enemy

The first enemy is an original goblin-wolf raider creature.

- `enemies/basic_enemy.png`: static frame.
- `enemies/enemy_walk_1.png` ... `enemy_walk_4.png`
- `enemies/enemy_walk_strip.png`: 4-frame horizontal strip.
- `enemies/enemy_death_1.png` ... `enemy_death_6.png`
- `enemies/enemy_death_strip.png`: 6-frame horizontal strip.

## Source Outputs

The processor outputs are kept for traceability:

- `raw-sheet.png`: original generated image copied into the asset folder.
- `raw-sheet-clean.png`: magenta background cleaned.
- `sheet-transparent.png`: full transparent processed sheet.
- `pipeline-meta.json`: frame extraction and QC metadata.
- `prompt-used.txt`: generation prompt summary.
- `animation.gif`: quick visual preview.

`sprite_manifest.json` provides stable paths and concepts for game integration.

## QC

Semantic animation frames were checked at 128x128. No final frame alpha content touches the output edge.
