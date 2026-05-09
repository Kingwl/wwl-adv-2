# 设计：单一敌人生命与死亡事件

## 状态

Implemented。

## 背景

当前战斗核心已经能产出 `DamageEvent`，但还没有把伤害应用到敌人，也没有死亡事件。为了保持 Playable Prototype 的范围可控，MVP 先只保留一种基础敌人，不做敌人类型表。

## 目标

- 只实现一种基础敌人。
- 敌人拥有固定默认生命值和固定击杀奖励。
- 伤害应用保持确定性，便于 GUT 测试。
- 死亡只产出一次事件，后续伤害不会重复结算。
- 已完成或已击败敌人不会继续移动或被索敌。
- 场景里每个可见敌人显示血条，血条按 `health / max_health` 更新。

## 非目标

- 暂不做多敌人类型。
- 暂不做护甲、抗性、精英怪、飞行怪。
- 暂不直接在伤害服务里给钱包加钱。
- 暂不做死亡动画或移除场景节点。
- 暂不为血条做正式美术、受击动画或数字飘字。

## 基础敌人

默认值：

| Stat | Value |
| --- | ---: |
| Health | 20 |
| Speed | 1.0 cells/s |
| Kill reward | 5 gold |

`Enemy` 运行时字段：

```text
id: String
speed_cells_per_second: float
max_health: float
health: float
kill_reward: int
path_distance: float
completed: bool
defeated: bool
```

`completed` 表示走到路径终点，`defeated` 表示被击杀。两者都不再作为有效攻击目标。

## 伤害应用

新增核心服务：

```text
EnemyDamageService.apply_damage_events(enemies, damage_events) -> EnemyDamageResult
```

输入：

- 当前敌人数组。
- 来自塔攻击的 `DamageEvent` 数组。

输出：

```text
EnemyDamageResult
├── applied_damage_events
├── death_events
└── ignored_damage_events
```

当伤害让 `health <= 0`：

- `health` clamp 到 `0`。
- `defeated = true`。
- 产出一个 `EnemyDeathEvent`。

`EnemyDeathEvent`：

```text
enemy_id: String
reward_gold: int
source_tower_id: String
```

后续经济系统根据死亡事件调用：

```text
wallet.earn(reward_gold, KILL_ENEMY, enemy_id)
```

## 场景血条

`BoardView` 在绘制敌人圆点后绘制一条跟随敌人的血条：

- 血条位于敌人上方。
- 剩余比例为 `clamp(health / max_health, 0, 1)`。
- 比例高于 50% 显示绿色，25%-50% 显示黄色，低于 25% 显示红色。
- 已完成或已击败敌人不在 `get_visible_enemies()` 中返回，因此不会继续显示血条。

## 测试覆盖

- 默认敌人是单一 MVP 配置。
- 非致命伤害会降低生命值。
- 致命伤害会标记 defeated 并产出死亡事件。
- 已击败敌人不会重复产出死亡事件。
- 不存在的 enemy id 会被忽略。
- 已击败敌人不会继续移动。
- 索敌会忽略已击败敌人。

## Next

- 波次系统生成多个基础敌人。
- 后续敌人类型表接管 HP、速度和奖励数值。
