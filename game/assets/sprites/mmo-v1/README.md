# MMO v1 Sprite 资产

这个包包含用于塔防 prototype 的原创 high-fantasy MMO 风格资产。视觉方向借鉴广义 Warcraft-like 奇幻原型，但避免精确的 World of Warcraft 单位、建筑、logo、命名生物或可识别轮廓。

## 塔

所有塔 frame 都是 128x128 透明 PNG。

- `towers/single_tower.png`：静态人类王国弩炮守卫塔。
- `towers/single_tower_attack_1.png` ... `single_tower_attack_4.png`
- `towers/single_tower_attack_strip.png`：4-frame 横向 strip。
- `towers/area_tower.png`：静态矮人风格攻城迫击炮塔。
- `towers/area_tower_attack_1.png` ... `area_tower_attack_4.png`
- `towers/area_tower_attack_strip.png`：4-frame 横向 strip。
- `towers/slow_tower.png`：静态冰霜水晶尖塔。
- `towers/slow_tower_attack_1.png` ... `slow_tower_attack_4.png`
- `towers/slow_tower_attack_strip.png`：4-frame 横向 strip。

## 敌人

第一个敌人是原创 goblin-wolf raider 生物。

- `enemies/basic_enemy.png`：静态 frame。
- `enemies/enemy_walk_1.png` ... `enemy_walk_4.png`
- `enemies/enemy_walk_strip.png`：4-frame 横向 strip。
- `enemies/enemy_death_1.png` ... `enemy_death_6.png`
- `enemies/enemy_death_strip.png`：6-frame 横向 strip。

## 源输出

保留处理器输出以便追溯：

- `raw-sheet.png`：复制进资产目录的原始生成图片。
- `raw-sheet-clean.png`：清理洋红背景后的图片。
- `sheet-transparent.png`：完整透明处理 sheet。
- `pipeline-meta.json`：frame 提取和 QC 元数据。
- `prompt-used.txt`：生成 prompt 摘要。
- `animation.gif`：快速视觉预览。

`sprite_manifest.json` 为游戏集成提供稳定路径和概念。

## QC

语义动画 frame 已按 128x128 检查。最终 frame 的 alpha 内容没有触碰输出边缘。
