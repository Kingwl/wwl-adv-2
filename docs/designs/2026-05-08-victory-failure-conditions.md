# Design: 胜负条件和玩家生命

## Status

Implemented for the playable prototype.

## Context

当前核心循环已经有路径移动、波次生成、塔攻击、击杀奖励和波次奖励。要形成一局最小闭环，需要定义敌人到达终点后的处理、玩家失败条件，以及全部波次完成后的胜利条件。

## Goals

- 敌人到达路径终点时扣玩家生命。
- 每个漏怪敌人只扣一次生命。
- 玩家生命归零时判定失败。
- 所有波次清完且玩家未失败时判定胜利。
- 核心规则保持在 `scripts/core/`，方便 GUT 测试覆盖。
- BoardView 只负责显示生命和胜负状态，不拥有胜负规则。

## Non-Goals

- 暂不做不同敌人的不同漏怪伤害。
- 暂不做结算面板、暂停、重开或关卡选择。
- 暂不做失败后的资源惩罚。
- 暂不从 `CombatSimulation.enemies` 中清理已结束敌人。

## Rules

### Player Life

MVP 玩家生命：

```text
max_lives = 10
lives = 10
```

`PlayerLife.apply_leak_events()` 负责结算生命：

- 输入为本 tick 产生的 `EnemyLeakEvent` 数组。
- 每个事件默认扣 1 点生命。
- 生命最低为 0。
- `lives <= 0` 时 `failed = true`。
- 非 `EnemyLeakEvent` 对象会被忽略，避免场景层误传事件导致崩溃。

### Enemy Leak

敌人漏怪条件：

- `enemy.completed == true`
- `enemy.defeated == false`

`EnemyLeakService` 记录已经扣过生命的 enemy id：

- 同一个敌人只产生一次 `EnemyLeakEvent`。
- 被击败的敌人不会产生漏怪事件。
- 还在路径上的敌人不会产生漏怪事件。

### Outcome Priority

每个固定 tick 的结算顺序：

1. 波次生成新敌人。
2. 敌人沿路径移动。
3. 收集漏怪事件并扣生命。
4. 塔索敌、攻击并应用伤害。
5. 根据生命和波次状态判定胜负。

胜负优先级：

- 如果 `PlayerLife.failed == true`，本局失败。
- 否则如果 `WaveSpawnResult.all_waves_cleared == true`，本局胜利。
- 失败优先于胜利；如果最后一个敌人漏怪导致生命归零，即使波次同时清空也判定失败。
- 一旦 `game_won` 或 `game_failed` 成立，后续 tick 不再推进战斗，只返回当前结果状态。

## Core Types

新增：

```text
game/scripts/core/combat/enemy_leak_event.gd
game/scripts/core/combat/enemy_leak_service.gd
game/scripts/core/player/player_life.gd
```

扩展：

```text
game/scripts/core/combat/combat_tick_result.gd
```

新增字段：

```text
enemy_leak_events: Array[EnemyLeakEvent]
lives_remaining: int
game_won: bool
game_failed: bool
```

`CombatSimulation` 持有：

```text
enemy_leak_service: EnemyLeakService
player_life: PlayerLife
game_won: bool
game_failed: bool
```

## BoardView Integration

HUD 新增：

```text
Hud/Lives
```

展示规则：

- 初始显示 `Lives: 10`。
- 漏怪后显示当前生命，例如 `Lives: 9`。
- 漏怪但未失败时状态显示 `Enemy leaked. Lives: 9`。
- 失败时状态显示 `Defeat. Enemies breached the path.`。
- 胜利时状态显示 `Victory. All waves cleared.`。

## Test Coverage

新增或扩展的 GUT 覆盖：

- `PlayerLife` 初始生命、扣血、生命归零、忽略非漏怪事件。
- `EnemyLeakService` 对 completed enemy 产生一次漏怪事件。
- active enemy 和 defeated enemy 不产生漏怪事件。
- `CombatSimulation` 在敌人到达终点时扣生命。
- `CombatSimulation` 生命归零时设置 `game_failed`。
- `CombatSimulation` 全部波次清完且生命剩余时设置 `game_won`。
- `BoardView` 更新 Lives HUD。
- `BoardView` 展示漏怪、失败和胜利状态。

## Follow-Ups

- 为不同敌人配置不同 `life_damage`。
- 增加结算面板和重开流程。
- 增加 enemy cleanup service，避免长局中保留大量 completed/defeated enemy。
