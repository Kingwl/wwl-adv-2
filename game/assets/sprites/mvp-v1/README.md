# MVP Sprite Pack v1

Generated with the `generate2dsprite` skill for the first playable tower-defense prototype.

## Units

Located in `units/`.

| File | Use |
| --- | --- |
| `single_tower.png` | Single-target tower sprite |
| `area_tower.png` | Area mortar tower sprite |
| `slow_tower.png` | Slow / frost tower sprite |
| `basic_enemy.png` | First basic enemy sprite |
| `sheet-transparent.png` | 2x2 transparent source sheet |
| `raw-sheet.png` | Original generated sheet copy |

## FX

Located in `fx/`.

| File | Use |
| --- | --- |
| `single_projectile_1.png` ... `single_projectile_4.png` | Golden projectile frames |
| `single_projectile_strip.png` | Golden projectile 1x4 strip |
| `area_impact_1.png` ... `area_impact_4.png` | Orange explosion impact frames |
| `area_impact_strip.png` | Orange explosion 1x4 strip |
| `slow_impact_1.png` ... `slow_impact_4.png` | Ice slow impact frames |
| `slow_impact_strip.png` | Ice slow impact 1x4 strip |
| `sheet-transparent.png` | 3x4 transparent source sheet |
| `raw-sheet.png` | Original generated sheet copy |

## QC

- `pipeline-meta.json` in each folder records frame sizes, component counts, and edge-touch checks.
- Both generated sheets report no edge-touch frames.
- These assets are wired into `BoardView` for tower sprites, the basic enemy sprite, and attack feedback textures.
