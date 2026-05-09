# Design: 塔种类与框架

## Status

Core implemented; BoardView supports selecting and placing all three MVP tower types.

## Context

当前已有棋盘、放塔、资源和敌人路径移动。下一步要做塔的索敌和攻击，但在实现前需要先定塔的种类、共享属性、配置方式和行为边界。

本设计服务 Playable Prototype：先做可测、可扩展的塔框架，不追求最终数值。

## Goals

- 定义 MVP 三种基础塔。
- 统一塔的配置、运行时状态和战斗行为输入输出。
- 保持塔规则可用 GUT 单测，不依赖 Godot 场景树。
- 支持后续合成后阶级提升。
- 支持后续状态效果和更多塔族扩展。

## Non-Goals

- 暂不做完整技能树。
- 暂不做随机词条。
- 暂不做投射物飞行和命中特效。
- 暂不做最终数值平衡。

## MVP Tower Types

### Single Target

定位：稳定单体输出。

建议基础值：

| Stat | Tier 1 |
| --- | ---: |
| Damage | 10 |
| Range | 2.5 cells |
| Attack interval | 1.0s |
| Targeting | First |
| Effect | None |

### Area

定位：低频范围伤害。

建议基础值：

| Stat | Tier 1 |
| --- | ---: |
| Damage | 6 |
| Range | 2.0 cells |
| Attack interval | 1.4s |
| Splash radius | 0.75 cells |
| Targeting | First |
| Effect | Damage all enemies near target |

### Slow

定位：控制塔，低伤害，减速敌人。

建议基础值：

| Stat | Tier 1 |
| --- | ---: |
| Damage | 3 |
| Range | 2.25 cells |
| Attack interval | 1.2s |
| Slow multiplier | 0.6 |
| Slow duration | 1.5s |
| Targeting | First |

## Tier Scaling

MVP 使用简单倍率：

```text
effective_damage = base_damage * tier
effective_range = base_range + 0.25 * (tier - 1)
effective_attack_interval = base_attack_interval
```

减速塔：

```text
slow_duration = base_slow_duration + 0.25 * (tier - 1)
slow_multiplier 不随 tier 变化
```

后续可以改成配置表。

## Runtime Tower

现有 `GameTower` 扩展为运行时塔对象：

```text
id: String
tower_type: Type
tier: int
grid_position: Vector2i
cooldown_remaining: float
```

注意：

- `GameTower` 可以不直接知道 `Board`。
- `grid_position` 由放置服务或战斗系统设置。
- 合成服务负责生成高阶塔，但位置更新由上层编排。

## Tower Config

建议新增：

```text
game/scripts/core/towers/tower_config.gd
game/scripts/core/towers/tower_stats.gd
```

`TowerConfig` 负责根据 `type + tier` 返回有效属性：

```text
get_stats(tower_type: Type, tier: int) -> TowerStats
```

`TowerStats`：

```text
damage: float
range_cells: float
attack_interval: float
splash_radius_cells: float
slow_multiplier: float
slow_duration: float
targeting: Targeting
```

## Targeting

MVP 先只实现 `FIRST`，但 enum 预留：

```gdscript
enum Targeting {
	FIRST,
	LOWEST_HEALTH,
	NEAREST,
}
```

`FIRST` 定义为：

- 选择范围内 `path_distance` 最大的未完成敌人。
- 如果没有敌人在范围内，返回 `null`。

后续目标策略应独立成 service：

```text
targeting_service.gd
```

## Combat Output

塔攻击不直接播放动画，不直接销毁敌人。核心层只输出事件：

```text
AttackResult
├── succeeded: bool
├── tower_id: String
├── target_enemy_id: String
├── damage_events: Array[DamageEvent]
└── status_events: Array[StatusEvent]
```

`DamageEvent`：

```text
enemy_id: String
amount: float
source_tower_id: String
```

`StatusEvent`：

```text
enemy_id: String
status_type: SLOW
duration: float
multiplier: float
source_tower_id: String
```

这样后续场景层可以根据事件画特效，经济系统可以根据死亡事件发奖励。

## Attack Timing

塔有冷却：

```text
cooldown_remaining
```

规则：

- 每个 fixed tick 先减少 cooldown。
- `cooldown_remaining <= 0` 时可以攻击。
- 攻击成功后设置为 `attack_interval`。
- 没有目标时不重置冷却。

为了测试稳定，战斗系统使用固定 tick，不依赖真实帧率。

## Proposed Files

```text
game/scripts/core/towers/
├── tower.gd
├── tower_config.gd
├── tower_stats.gd
├── targeting_service.gd
└── tower_attack_service.gd

game/scripts/core/combat/
├── attack_result.gd
├── damage_event.gd
└── status_event.gd

game/test/gut/towers/
├── test_tower_config.gd
├── test_targeting_service.gd
└── test_tower_attack_service.gd
```

## Test Cases

### Tower Config

- 每种 MVP 塔类型能返回 tier 1 stats。
- tier 提升会增加伤害。
- range 按规则提升。

### Targeting

- 范围内没有敌人时返回 `null`。
- `FIRST` 选择 `path_distance` 最大的敌人。
- 完成的敌人不会被选中。
- 范围外敌人不会被选中。

### Attack

- 冷却未好时不能攻击。
- 有目标时产生 damage event。
- 单体塔只伤害目标。
- 范围塔伤害目标附近敌人。
- 减速塔产生 damage event 和 slow status event。
- 没有目标时不重置冷却。

## Implementation Roadmap

### Step 1: Tower Config

- [x] 增加 `TowerStats`。
- [x] 增加 `TowerConfig`。
- [x] 为三种 MVP 塔写 GUT 测试。

### Step 2: Runtime Tower Position

- [x] 给 `GameTower` 增加 `grid_position` 和 `cooldown_remaining`。
- [x] 更新合成测试，确保旧逻辑不破。
- [x] 放塔服务创建 tower registry 时使用该位置。

### Step 3: Targeting

- [x] 增加 `TargetingService`。
- [x] 基于塔位置、range 和敌人位置选择目标。
- [x] 先实现 `FIRST`。

### Step 4: Attack Events

- [x] 增加 `AttackResult`、`DamageEvent`、`StatusEvent`。
- [x] 增加 `TowerAttackService`。
- [x] 实现单体、范围、减速三类攻击事件。

### Step 5: Scene Feedback

- [x] BoardView 根据攻击事件显示简单线条和命中点。
- [x] 改为核心层 `CombatProjectile` 飞行，命中后再结算伤害和场景命中特效。

### Step 6: Scene Tower Selection

- [x] HUD 增加固定塔栏，包含 Single、Area、Slow 三个塔卡。
- [x] 塔卡显示塔名、价格、当前选中态；暂停或金币不足时不可购买。
- [x] 当前选择写入 `TowerPlacementService.basic_tower_type`。
- [x] BoardView 按塔型显示不同颜色。
- [x] 场景测试覆盖 Area 和 Slow 的放置结果。

## Open Questions

- 合成后的塔是否继承第一个塔的冷却，还是重置冷却。
- 范围塔 splash 是以目标为中心，还是以塔为中心。
- 减速效果是否可叠加。建议 MVP 不叠加，只刷新持续时间。
- 随机召唤是否替代手动选择。建议等合成 UI 接入后再设计概率和保底。
