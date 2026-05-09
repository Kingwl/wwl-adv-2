# Design: 固定 Tick 战斗模拟

## Status

Core and BoardView runtime integration implemented. Default runtime step reduced to 60 Hz after the 0.1s prototype step felt visibly choppy. BoardView now renders short-lived visual attack feedback from successful attacks.

## Context

战斗核心已经有路径移动、塔索敌攻击、伤害应用和死亡事件。现在需要一个统一编排层，让这些规则按固定步长运行，而不是直接依赖 Godot 每帧 `delta`。

## Goals

- 使用固定 tick 推进战斗核心。
- 累积真实帧 delta，只在累计值达到固定步长时结算。
- 保持核心模拟可单测，不依赖 Godot 场景树。
- 每个 tick 串起敌人移动、塔攻击、伤害结算和死亡事件。
- 输出结构化结果，供场景层后续绘制攻击反馈或死亡反馈。

## Non-Goals

- 暂不做波次生成。
- 暂不做状态效果持续时间结算。
- 暂不做攻击轨迹或命中特效。

## Fixed Step

MVP 默认：

```text
fixed_step_seconds = 1 / 60
```

早期原型使用 `0.1s`，规则测试简单但画面只有 10Hz 的位置更新。当前默认改为 60Hz，仍然通过固定 tick 保持确定性。后续如果战斗规则变重，可以把核心 tick 降到 30Hz，并在 BoardView 增加渲染插值。

场景层后续使用方式：

```gdscript
func _process(delta: float) -> void:
	var tick_results := combat_simulation.advance(delta)
	for tick_result in tick_results:
		_apply_visual_feedback(tick_result)
	queue_redraw()
```

`advance(delta)` 只负责把真实帧时间转换为一个或多个固定 tick：

- `delta < fixed_step`：只累积，不推进规则。
- `delta == fixed_step`：推进一次。
- `delta > fixed_step`：推进多次，并保留余量。

## Tick Order

单个 tick 顺序：

1. 波次生成新敌人。
2. 推进所有未完成、未击败敌人。
3. 结算漏怪和玩家生命。
4. 逐个塔减少冷却并尝试索敌攻击。
5. 汇总攻击产生的 `DamageEvent` 和 `StatusEvent`。
6. 应用伤害事件。
7. 产出死亡事件。
8. 判定胜利或失败。

## Core Types

新增：

```text
game/scripts/core/combat/combat_simulation.gd
game/scripts/core/combat/combat_tick_result.gd
```

`CombatSimulation` 持有：

```text
towers: Array
enemies: Array
path_follower: PathFollower
fixed_step_seconds: float
accumulator_seconds: float
tower_attack_service: TowerAttackService
enemy_damage_service: EnemyDamageService
```

`CombatTickResult`：

```text
delta_seconds: float
attack_results: Array[AttackResult]
damage_events: Array[DamageEvent]
status_events: Array[StatusEvent]
damage_result: EnemyDamageResult
```

## Test Coverage

- 不足一个 fixed step 时只累积，不推进。
- 大 delta 会推进多个 fixed step，并保留余量。
- tick 会推进敌人、触发塔攻击、应用伤害。
- 致命伤害会产出死亡事件。
- 塔不会在 fixed step 之前提前攻击。

## Visual Feedback

Current attack feedback is scene-only:

- `CombatSimulation` still applies damage immediately in the fixed tick.
- BoardView reads successful `AttackResult` values and draws a short projectile trail from tower to target.
- Feedback lifetime is visual only and does not affect hit timing.

If attacks need real projectile travel time, add projectile entities to the core simulation and move damage application to projectile impact.

## Next

- 设计真实投射物实体和命中时机，如果玩法需要非瞬发攻击。
- 增加状态效果持续时间结算。
