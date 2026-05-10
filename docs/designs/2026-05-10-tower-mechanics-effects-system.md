# 设计：塔机制、效果、状态和特效体系

## 状态

Accepted

## 第一版实现状态

已实现核心规则层的通用状态运行时：

- `StatusEvent` 支持 `slow`、`burn` 和 `poison`，并携带 tick 伤害、攻击类型、伤害类型和叠加策略。
- `StatusEffect`/`StatusEffectService` 负责把命中状态挂到敌人身上、推进剩余时间、按完整 tick interval 生成 DoT `DamageEvent`。
- `slow` 使用 `strongest` 叠加规则，敌人移动通过 `PathFollower` 读取当前最强移动倍率。
- `burn` 和 `poison` 预留为 `refresh` DoT；DoT 伤害事件会继续走攻击/防御/伤害类型和种族抗性结算。
- `CombatSimulation` 已把已有状态推进接入固定 tick，新命中状态从下一次完整状态 tick 开始生效。
- 塔 tier 已通过 `effects[]` 表达命中效果：`damage_primary`、`splash_damage` 和 `apply_status`。
- `ProjectileService` 消费 `effects[]` 生成伤害和状态事件，不再按塔类型写死 Area/Slow/Flame 分支。
- Flame 塔已通过数据文件和通用状态效果施加 `burn`，并有塔 sprite、火焰命中特效和 gameplay smoke 视觉 checkpoint。
- `game/data/towers/towers.json` 和 `game/data/schemas/towers.schema.json` 已纳入 `check-assets.sh`，校验塔枚举、投射物字段、tier 成长和 effect 语义。

尚未实现：

- 毒针塔、雷霆塔等后续新塔接入。
- `StatusAppliedEvent`、`StatusTickEvent`、`StatusExpiredEvent` 和 `VisualEvent` 的独立事件对象。
- 状态图标、独立 DoT tick 视觉表现和 HUD 展示。

## 背景

项目已经有三座基础塔：Single、Area、Slow。它们目前通过塔类型、投射物字段和少量专用状态字段来表达攻击差异。随着初期塔扩展到弩塔、炮塔、冰霜塔、火焰塔、毒针塔和雷霆塔，仅靠专用字段会快速膨胀。

本设计承接：

- `2026-05-10-attack-defense-damage-system.md`：攻击、防御、伤害类型和种族抗性。
- `2026-05-10-initial-tower-roster.md`：初期塔名单和实现批次。

核心方向是把塔机制拆成：

```text
攻击模式 attack_pattern
效果列表 effects
状态 status_effects
视觉事件 visual_events
```

短期优先支持 Debuff 和 DoT，长期保留 Buff、光环、地面区域、召唤和复杂叠层的扩展口。

## 目标

- 用统一机制支撑冰霜减速、火焰灼烧、毒素中毒和闪电连锁。
- 避免为每座塔写死独立战斗逻辑。
- 保持核心规则确定性，不依赖 Godot 场景、节点或帧渲染。
- 让视觉特效由规则事件驱动，但不影响规则结果。
- 为长期 Buff、Debuff、DoT、光环、地面区域和召唤机制保留可扩展结构。

## 非目标

- 第一版不实现复杂 Buff 光环塔。
- 第一版不实现地面持续区域、陷阱、召唤单位或多段技能脚本。
- 第一版不实现完全免疫、吸收、元素反应或复杂状态组合。
- 第一版不要求所有视觉特效资源都准备完毕。

## 方案

### 总体模型

```text
TowerDefinition
├── weapon_type
├── attack_type
├── damage_school
├── attack_pattern
├── effects[]
└── visual_key
```

其中：

- `attack_pattern` 决定怎么命中目标。
- `effects` 决定命中、tick、进入区域或退出区域时发生什么。
- `visual_key` 只给表现层选素材，不参与规则。

### 攻击模式

| 模式 | 英文枚举 | 说明 | 短期状态 |
| --- | --- | --- | --- |
| 单体弹道 | `single_projectile` | 一发投射物命中一个目标 | 已有基础，短期保留 |
| 溅射弹道 | `splash_projectile` | 命中主目标后影响半径内敌人 | 已有基础，短期保留 |
| 状态弹道 | `status_projectile` | 单体命中并附加状态 | 已有 Slow 雏形，短期泛化 |
| 持续状态 | `status_dot` | 命中后附加 DoT 或 Debuff | 短期新增 |
| 连锁 | `chain` | 命中后跳到多个目标 | 雷霆塔阶段新增 |
| 光环 | `aura` | 持续影响范围内塔或敌人 | 长期 |
| 地面区域 | `ground_area` | 创建持续区域，敌人进入后受影响 | 长期 |
| 多重射击 | `multi_shot` | 同次攻击发射多发 | 长期 |
| 召唤/陷阱 | `summon_or_trap` | 生成临时单位或一次性触发物 | 长期 |

### 效果类型

| 效果 | 英文枚举 | 说明 | 短期状态 |
| --- | --- | --- | --- |
| 主目标伤害 | `damage_primary` | 对命中主目标造成一次伤害 | 已实现 |
| 溅射伤害 | `splash_damage` | 对命中点范围内敌人造成伤害 | 已实现 |
| 附加状态 | `apply_status` | 给敌人添加状态 | 已实现 |
| 连锁伤害 | `chain_damage` | 查找额外目标并造成伤害 | 雷霆塔阶段 |
| 易伤 | `vulnerability` | 目标承伤提高 | 长期 |
| 护甲削弱 | `armor_break` | 降低护甲或防御效果 | 长期 |
| 塔 Buff | `tower_buff` | 提升塔伤害、攻速、射程等 | 长期 |
| 光环 | `aura` | 持续范围效果 | 长期 |
| 召唤 | `summon` | 生成临时战斗实体 | 长期 |
| 视觉事件 | `visual` | 只产生表现事件 | 可随时补 |

### 状态类型

| 状态 | 英文枚举 | 类型 | 作用 | 第一版叠加规则 |
| --- | --- | --- | --- | --- |
| 减速 | `slow` | Debuff | 降低移动速度 | 同类取最强，刷新持续时间 |
| 灼烧 | `burn` | DoT | 火焰持续伤害 | 刷新持续时间，不叠层 |
| 中毒 | `poison` | DoT | 毒素持续伤害 | 刷新持续时间，后续可叠层 |
| 感电 | `shock` | Debuff/标记 | 强化闪电或连锁 | 长期，先不实现 |
| 易伤 | `vulnerable` | Debuff | 提高承伤 | 长期 |
| 冻结 | `freeze` | 控制 | 短时停止移动 | 长期，谨慎 |
| 鼓舞 | `inspire` | Buff | 提高附近塔能力 | 长期 |

### 状态字段

```gdscript
{
  "status_type": "burn",
  "source_tower_id": "tower-1",
  "damage_school": "FIRE",
  "duration_seconds": 3.0,
  "remaining_seconds": 3.0,
  "tick_interval_seconds": 1.0,
  "tick_damage": 2.0,
  "move_speed_multiplier": 1.0,
  "stack_policy": "refresh"
}
```

字段含义：

- `duration_seconds`：状态总时长。
- `remaining_seconds`：当前剩余时长。
- `tick_interval_seconds`：DoT tick 间隔；非 DoT 可为 `0.0`。
- `tick_damage`：每 tick 基础伤害，仍要走攻击/防御/伤害类型结算。
- `move_speed_multiplier`：减速倍率，例如 `0.6`。
- `stack_policy`：叠加规则。

### 叠加规则

| 规则 | 英文枚举 | 用途 |
| --- | --- | --- |
| 刷新 | `refresh` | 同来源或同类型状态只刷新持续时间 |
| 取最强 | `strongest` | 减速类状态取更低移动倍率，同时刷新持续时间 |
| 替换 | `replace` | 新状态直接覆盖旧状态 |
| 叠层 | `stack` | 增加层数，有上限 |
| 并存 | `independent` | 不同来源可并存 |

第一版只需要：

- `slow` 使用 `strongest`。
- `burn` 使用 `refresh`。
- `poison` 使用 `refresh`。

`stack` 留给毒素后续扩展。

### 事件模型

规则层输出事件，表现层订阅事件。

```text
DamageEvent
StatusAppliedEvent
StatusTickEvent
StatusExpiredEvent
ProjectileImpactEvent
VisualEvent
```

短期可以复用现有 `DamageEvent`、`StatusEvent`、`ProjectileImpactEvent`，但应逐步把 Slow 专用字段迁移到通用状态结构。

视觉事件不影响规则结果：

```gdscript
{
  "visual_key": "burn_tick",
  "grid_space_position": Vector2(3.5, 2.5),
  "source_id": "tower-4",
  "target_id": "enemy-2"
}
```

### Tick 顺序

固定 tick 中建议顺序：

1. 波次生成敌人。
2. 更新敌人已有状态剩余时间和移动倍率。
3. 敌人移动。
4. 塔攻击并生成投射物。
5. 投射物移动并命中。
6. 命中效果产生即时伤害和新状态。
7. 状态 tick 产生 DoT 伤害。
8. 应用所有伤害、死亡、奖励、漏怪和胜负状态。

开放点：DoT 是在投射物命中同 tick 立即 tick，还是从下一个 tick 开始。第一版建议从下一个完整 `tick_interval` 开始，避免命中瞬间造成两段伤害。

### 短期塔机制映射

| 塔 | 攻击模式 | 效果 |
| --- | --- | --- |
| 弩塔 | `single_projectile` | 即时物理伤害 |
| 炮塔 | `splash_projectile` | 即时物理伤害 + 溅射 |
| 冰霜塔 | `status_projectile` | 冰霜伤害 + `slow` |
| 火焰塔 | `status_dot` | 火焰伤害 + `burn` DoT |
| 毒针塔 | `status_dot` | 毒素伤害 + `poison` DoT |
| 雷霆塔 | `chain` | 闪电伤害 + 跳跃目标 |

### 长期塔机制映射

| 塔 | 机制 |
| --- | --- |
| 旋刃塔 | 近距离环形伤害 |
| 奥术塔 | 穿抗、高伤、打精英 |
| 暗影塔 | 易伤、诅咒、削弱 |
| 圣光塔 | 克亡灵、辅助或反亡灵特化 |
| 地震塔 | 地面区域持续伤害 |
| 风暴塔 | 大范围随机落雷 |
| 炼金塔 | 毒火混合药剂、范围异常 |
| 光环塔 | 给附近塔加攻速、伤害或射程 |
| 陷阱塔 | 周期触发或一次性爆发 |

### 配置草案

火焰塔：

```gdscript
{
  "id": "flame_tower",
  "weapon_type": "SPELL",
  "attack_type": "MAGIC",
  "damage_school": "FIRE",
  "attack_pattern": "status_dot",
  "effects": [
    {
      "trigger": "on_hit",
      "type": "damage",
      "value": 4.0
    },
    {
      "trigger": "on_hit",
      "type": "apply_status",
      "status_type": "burn",
      "duration_seconds": 3.0,
      "tick_interval_seconds": 1.0,
      "tick_damage": 2.0,
      "damage_school": "FIRE",
      "stack_policy": "refresh"
    }
  ],
  "visual_key": "flame"
}
```

冰霜塔：

```gdscript
{
  "id": "frost_tower",
  "weapon_type": "SPELL",
  "attack_type": "MAGIC",
  "damage_school": "FROST",
  "attack_pattern": "status_projectile",
  "effects": [
    {
      "trigger": "on_hit",
      "type": "damage",
      "value": 3.0
    },
    {
      "trigger": "on_hit",
      "type": "apply_status",
      "status_type": "slow",
      "duration_seconds": 1.5,
      "move_speed_multiplier": 0.6,
      "stack_policy": "strongest"
    }
  ],
  "visual_key": "frost"
}
```

## 实现计划

1. 新增通用 `StatusEffect` 数据结构。
2. 新增状态容器或服务，负责添加、刷新、取最强、过期和 tick。
3. 将当前 Slow 专用 `StatusEvent` 迁移到通用 `StatusEffect`。
4. 增加 DoT tick，对 `burn` 和 `poison` 产生伤害事件。
5. 让 DoT 伤害也经过攻击/防御/伤害类型和种族抗性结算。
6. 增加轻量 `VisualEvent` 或扩展现有 projectile impact event，给 BoardView 播特效。
7. 新增火焰塔和毒针塔。
8. 新增雷霆塔连锁攻击模式。
9. 长期再做光环、地面区域、Buff 和复杂叠层。

## 测试要求

- `test_status_effect_service.gd` 覆盖状态添加、刷新、取最强、过期和 tick。
- `test_projectile_service.gd` 覆盖命中时附加状态和生成视觉事件。
- `test_enemy_damage_service.gd` 覆盖 DoT 伤害仍走最终伤害公式。
- `test_combat_simulation.gd` 覆盖固定 tick 中状态移动倍率、DoT 伤害、死亡和奖励。
- `test_tower_config.gd` 覆盖塔配置里的 `attack_pattern`、JSON 加载、schema 语义和 `effects`。
- `check-gameplay-smoke.sh` 后续增加火焰或毒素 DoT 的代表 scenario。

## 替代方案

- 为每种塔写独立逻辑。短期简单，但火焰、毒素、雷霆、暗影、光环都会变成重复代码。
- 先实现完整技能脚本系统。扩展性强，但目前体量过大，测试和数据 schema 也会膨胀。
- 把视觉特效直接写进核心事件处理。会破坏核心规则和 Godot 表现层边界。

## 风险

- 效果配置过早泛化会增加 schema 和测试成本。
- DoT、即时伤害和种族抗性叠乘后可能导致伤害爆发或过低。
- 视觉事件如果和规则事件耦合太紧，会增加场景测试维护成本。
- Buff 和 Debuff 共享结构时容易混淆作用对象，短期应只做敌人 Debuff。

## 开放问题

- DoT 第一次伤害是在命中后立即触发，还是等待第一个 tick interval？
- DoT 击杀的奖励归因应归给原塔、状态来源，还是状态本身？
- 毒素后续是否允许叠层，最大层数是多少？
- 雷霆连锁是否按距离、路径进度还是随机目标跳跃？
- 视觉事件是否需要持久化到 replay/smoke trace，还是只在场景层消费？
