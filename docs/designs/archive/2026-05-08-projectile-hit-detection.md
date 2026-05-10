# 设计：投射物命中判断

## 状态

Implemented。

## 背景

之前塔攻击在核心战斗里会立即产出 `DamageEvent`，场景层只画一段飞行反馈。这让投射物只是表现层效果，不能支持飞行时间、目标提前死亡、漏怪导致丢失、真正命中后再爆炸等规则。

## 目标

- 塔攻击先创建核心层 `CombatProjectile`。
- 投射物按固定 tick 在格子空间移动。
- 投射物接近目标到命中半径后，才产出伤害和状态事件。
- 目标已死亡或已到终点时，投射物 miss，不结算伤害。
- 范围塔在命中点按 splash 半径找敌人。
- 场景层绘制当前 active projectiles，并只在 `ProjectileImpactEvent` 出现时播放命中特效。

## 核心类型

```text
CombatProjectile
├── id
├── tower_id
├── target_enemy_id
├── tower_type
├── position
├── speed_cells_per_second
├── hit_radius_cells
├── damage
├── splash_radius_cells
├── slow_multiplier
├── slow_duration
└── active
```

```text
ProjectileAdvanceResult
├── active_projectiles
├── damage_events
├── status_events
├── impact_events
└── missed_projectile_ids
```

## Tick 顺序

`CombatSimulation.tick()` 当前顺序：

1. 波次生成。
2. 敌人移动。
3. 漏怪和生命结算。
4. 塔索敌并创建投射物。
5. 投射物推进并执行命中判断。
6. 命中后产出的 `DamageEvent` 进入 `EnemyDamageService`。
7. 胜负状态更新。

这意味着塔的冷却从发射时开始，伤害从命中时开始。

## Scene Rules

- `BoardView` 绘制 `combat_simulation.projectiles` 作为真实飞行中的投射物。
- 命中特效来自 `CombatTickResult.projectile_impact_events`。
- 命中特效生成后不会在同一个 `_process(delta)` 中立刻衰减，确保至少显示一帧。

## 测试

- `test_projectile_service.gd` 覆盖移动、命中、范围伤害、减速状态和 miss。
- `test_combat_simulation.gd` 覆盖发射与命中分离。
- `test_main_scene.gd` 覆盖场景中 active projectile 和命中特效。
