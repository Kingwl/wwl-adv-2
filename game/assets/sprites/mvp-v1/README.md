# MVP Sprite 包 v1

使用 `generate2dsprite` skill 为首个可玩塔防 prototype 生成。

## 单位

位于 `units/`。

| 文件 | 用途 |
| --- | --- |
| `single_tower.png` | 单体目标塔 sprite |
| `area_tower.png` | 范围迫击炮塔 sprite |
| `slow_tower.png` | 减速/冰霜塔 sprite |
| `basic_enemy.png` | 第一个基础敌人 sprite |
| `sheet-transparent.png` | 2x2 透明源 sheet |
| `raw-sheet.png` | 原始生成 sheet 副本 |

## FX

位于 `fx/`。

| 文件 | 用途 |
| --- | --- |
| `single_projectile_1.png` ... `single_projectile_4.png` | 金色投射物 frame |
| `single_projectile_strip.png` | 金色投射物 1x4 strip |
| `area_impact_1.png` ... `area_impact_4.png` | 橙色爆炸命中特效 frame |
| `area_impact_strip.png` | 橙色爆炸 1x4 strip |
| `slow_impact_1.png` ... `slow_impact_4.png` | 冰霜减速命中特效 frame |
| `slow_impact_strip.png` | 冰霜减速 1x4 strip |
| `sheet-transparent.png` | 3x4 透明源 sheet |
| `raw-sheet.png` | 原始生成 sheet 副本 |

## QC

- 每个目录中的 `pipeline-meta.json` 记录 frame 尺寸、组件数量和 edge-touch 检查。
- 两张生成 sheet 都报告没有 edge-touch frame。
- 这些资产已接入 `BoardView`，用于塔 sprite、基础敌人 sprite 和攻击反馈贴图。
