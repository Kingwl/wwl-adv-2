# 设计：波次系统

## 状态

核心波次生成、CombatSimulation 集成、波次奖励、BoardView 敌人渲染、Wave HUD、漏怪处理和结果状态已实现。

## 背景

当前已经有单一敌人、路径移动、固定 tick 战斗模拟、塔攻击、伤害结算和击杀奖励。下一步需要把“一个 prototype enemy”扩展成可生成多个敌人的波次系统。

本设计服务 Playable Prototype：先做可测试、确定性的最小波次，不做复杂关卡编辑器。

## 目标

- 支持按固定间隔生成一波敌人。
- 支持多波顺序执行。
- 仍然只使用一种基础敌人。
- 波次核心不依赖 Godot 场景树。
- 能判断当前波是否完成，以及全部波次是否完成。
- 能输出波次完成事件，用于后续发放波次奖励。
- 能被 `CombatSimulation` 使用：生成出的敌人进入 simulation 的 `enemies` 数组。

## 非目标

- 暂不做多敌人类型。
- 暂不做随机生成。
- 暂不做复杂出怪队列、分路、空中单位。
- 暂不做难度曲线和最终数值平衡。
- 暂不做结算面板、暂停、重开或关卡选择。

## MVP 波次规则

一局先规划 3 波：

| 波次 | 敌人数量 | 生成间隔 | 敌人 HP | 速度 | 击杀奖励 | 波次奖励 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 5 | 0.8s | 20 | 1.0 | 5 | 20 |
| 2 | 7 | 0.7s | 24 | 1.0 | 5 | 25 |
| 3 | 10 | 0.6s | 30 | 1.1 | 6 | 35 |

虽然仍然是同一种基础敌人，但允许波次覆盖 HP、速度和奖励，用于形成最小成长压力。后续如果引入敌人类型，这些字段可以迁移到 enemy config。

## 核心类型

建议新增：

```text
game/scripts/core/waves/
├── wave_definition.gd
├── wave_state.gd
├── wave_spawn_result.gd
├── wave_clear_event.gd
└── wave_spawner.gd

game/test/gut/waves/
└── test_wave_spawner.gd
```

### WaveDefinition

```text
wave_id: String
enemy_count: int
spawn_interval_seconds: float
enemy_max_health: float
enemy_speed_cells_per_second: float
enemy_kill_reward: int
clear_reward_gold: int
```

规则：

- `enemy_count > 0`
- `spawn_interval_seconds > 0`
- `enemy_max_health > 0`
- `enemy_speed_cells_per_second > 0`
- `enemy_kill_reward >= 0`
- `clear_reward_gold >= 0`

### WaveState

```text
wave_definition: WaveDefinition
started: bool
cleared: bool
spawned_count: int
spawn_elapsed_seconds: float
active_enemy_ids: Dictionary
```

`active_enemy_ids` 用于判断本波生成过且还没结束的敌人：

- 敌人生成时加入。
- 敌人 `defeated` 或 `completed` 后移除。
- 当 `spawned_count == enemy_count` 且 `active_enemy_ids` 为空，波次完成。

### WaveSpawnResult

```text
spawned_enemies: Array[Enemy]
wave_clear_events: Array[WaveClearEvent]
current_wave_index: int
all_waves_cleared: bool
```

`WaveSpawner.advance(delta, existing_enemies)` 每个固定 tick 调用一次，返回这次新生成的敌人和可能发生的波次完成事件。

### WaveClearEvent

```text
wave_id: String
reward_gold: int
```

后续经济层根据该事件调用：

```text
wallet.earn(reward_gold, CLEAR_WAVE, wave_id)
```

### WaveSpawner

职责：

- 持有 `Array[WaveDefinition]`。
- 当前只运行一个 active wave。
- 根据固定 tick 的 `delta_seconds` 累积生成计时。
- 生成 Enemy id，例如：

```text
wave-1-enemy-1
wave-1-enemy-2
```

- 当当前波清完，产出 `WaveClearEvent`。
- 下一波启动策略先用自动启动：上一波 clear 后，下一个 tick 开始下一波。

## 与 CombatSimulation 集成

推荐在 `CombatSimulation.tick()` 的最前面执行 wave spawn：

1. `WaveSpawner.advance(delta_seconds, enemies)` 生成新敌人。
2. 把新敌人 append 到 `enemies`。
3. 推进所有未完成、未击败敌人。
4. 塔攻击。
5. 伤害结算。
6. 死亡事件。
7. 返回 `CombatTickResult`，其中包含 wave spawn / clear 信息。

这样场景层只持有一个 `CombatSimulation`，不需要自己决定什么时候生成敌人。

`CombatTickResult` 后续扩展：

```text
spawned_enemies: Array[Enemy]
wave_clear_events: Array[WaveClearEvent]
all_waves_cleared: bool
```

## 敌人 Lifecycle

MVP 不立即从 `enemies` 数组中删除敌人，先保留对象并通过状态过滤：

- `defeated = true`：被塔击杀，不再移动、不再被索敌。
- `completed = true`：走到终点，不再移动、不再被索敌，并由 `EnemyLeakService` 只扣一次玩家生命。

`WaveSpawner` 通过状态判断 active enemy 是否结束。后续性能或渲染需要时，再加 cleanup service。

## 生命和结果集成

胜负规则详见 `docs/designs/2026-05-08-victory-failure-conditions.md`。

MVP 决策：

- 玩家初始生命为 10。
- 单个漏怪默认扣 1 点生命。
- 生命归零时失败。
- 全部波次清完且玩家未失败时胜利。
- 失败优先于胜利。

## 奖励

奖励分两层：

- 击杀奖励：已有 `EnemyDeathEvent -> KillRewardService`。
- 波次奖励：新增 `WaveClearEvent -> WaveRewardService` 或扩展 `KillRewardService` 为更通用的 reward service。

MVP 建议新增 `WaveRewardService`，避免把两个 reason 混在一个方法里。

## 测试用例

先写 GUT 测试：

- wave definition 参数校验。
- 不足 spawn interval 时不生成敌人。
- 达到 spawn interval 时生成一个敌人。
- 大 delta 可以生成多个敌人，但不能超过 `enemy_count`。
- 生成敌人的 id、hp、speed、reward 来自 wave definition。
- 所有本波敌人结束后，产出一次 `WaveClearEvent`。
- 波清完后自动进入下一波。
- 所有波清完后 `all_waves_cleared = true`。

## 实现路线图

### 步骤 1：核心波次生成器

- [x] 增加 `WaveDefinition`。
- [x] 增加 `WaveSpawner` 和 `WaveSpawnResult`。
- [x] 用 GUT 覆盖生成间隔、敌人数和敌人属性。

### 步骤 2：波次清空

- [x] 增加 `WaveClearEvent`。
- [x] 根据 `defeated/completed` 判断波次完成。
- [x] 增加 GUT 测试确保 clear event 只产出一次。

### 步骤 3：战斗集成

- [x] `CombatSimulation` 接入 `WaveSpawner`。
- [x] `CombatTickResult` 返回 spawned enemies 和 wave clear events。
- [x] 更新核心战斗测试。

### 步骤 4：经济集成

- [x] 增加波次奖励服务。
- [x] BoardView 根据 wave clear event 发放 `CLEAR_WAVE` 奖励。
- [x] HUD 后续显示当前波次。

### 步骤 5：BoardView 集成

- [x] BoardView 使用 `WaveSpawner` 初始化 `CombatSimulation`。
- [x] BoardView 渲染 `combat_simulation.enemies` 中的可见敌人。
- [x] 默认关卡使用 3 波 MVP 配置。

## 决策s

- 敌人到达终点会扣玩家生命。
- 波次自动开始。
- MVP 不允许上一波未清完时提前生成下一波。
