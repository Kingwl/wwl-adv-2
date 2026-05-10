# 设计：塔升级机制

## 状态

Implemented

## 背景

Prototype 已经实现点击已放置塔后显示操作菜单，并支持直接升级和拆除。当前升级按塔数据文件读取 tier 快照：Single 提升单体伤害和攻速，Area 提升溅射，Slow 提升减速效果，Flame 提升灼烧 DoT。

接下来塔会扩展到弩塔、炮塔、冰霜塔、火焰塔、毒针塔和雷霆塔，同时引入攻击类型、防御类型、伤害类型、种族抗性、通用状态、DoT 和视觉事件。近期升级机制先不做性质变化，只做数值成长；每次升级必须同时提升伤害和攻击范围，其他成长也只允许调整已有机制的数值参数。

本设计承接：

- `2026-05-10-tower-action-menu-upgrades.md`：当前操作菜单、直接升级和拆除返还。
- `2026-05-10-attack-defense-damage-system.md`：攻击、防御、伤害类型和种族抗性。
- `2026-05-10-initial-tower-roster.md`：初期塔名单。
- `2026-05-10-tower-mechanics-effects-system.md`：攻击模式、效果、状态、DoT 和视觉事件。

## 目标

- 保留直接升级作为近期主升级方式。
- 每次升级都严格提升 `damage` 和 `range_cells`。
- 让每座塔的升级在数值上强化其核心定位，避免新增或替换机制。
- 用配置表达 tier、费用、属性数值、效果数值和 UI 预览，方便迁移到数据文件。
- 与攻击类型、伤害类型、状态效果、DoT、连锁等机制兼容。
- 保持核心规则确定性，升级成功或失败都可通过 GUT 覆盖。
- 保留未来分支进化和合成经济的扩展空间。

## 非目标

- 第一版不做随机升级、科技树、局外成长或永久养成。
- 第一版不做二选一分支升级；只保留数据结构空间。
- 第一版不做升级建造时间、升级中停火或动画锁定。
- 第一版不让线性 tier 改变塔的基础攻击类型和伤害类型。
- 第一版不在升级时新增状态、额外弹道、额外攻击模式、额外伤害类型或新目标策略。
- 第一版不解决完整数值平衡，只定义机制和初始曲线方向。

## 方案

### 核心规则

短期继续采用“选中塔 -> 操作菜单 -> Upgrade”的直接升级流程。

每座塔有一个 `tower_id`、一个当前 `tier` 和一个累计投入 `invested_gold`。升级是一次核心规则 mutation：

1. 根据塔 ID 找到塔实例。
2. 读取该塔当前 tier 的下一次升级费用。
3. 校验未满级、金币足够、游戏状态允许操作。
4. 扣除金币。
5. 将 tower tier 提升到下一档。
6. 将升级费用加入 `invested_gold`。
7. 同步战斗系统中的塔状态。

失败路径必须不改变金币、tier、累计投入、棋盘 occupant 或战斗塔列表。

拆除继续按累计投入返还：

```text
refund = floor((build_cost + all_paid_upgrade_costs) * refund_ratio)
```

当前返还比例仍为 `50%`。如果后续每种塔有不同建造费用，建造费用也应进入 tower definition，而不是继续只放在全局经济配置里。

### Tier 语义

第一版每座塔建议 3 级：

| Tier | 语义 | 设计要求 |
| --- | --- | --- |
| 1 | 基础身份 | 玩家能看懂这座塔的核心功能。 |
| 2 | 数值强化 | 必须提升伤害和攻击范围，可小幅强化已有机制的数值。 |
| 3 | 数值上限 | 继续提升伤害和攻击范围，可进一步强化已有机制的数值，但不新增机制。 |

Tier 定义使用“完整快照”，不使用增量补丁。也就是 tier 2 直接声明最终 damage/range/effects，而不是声明 `+8 damage`。这样做有几个好处：

- 存档只需要记录 tower id 和 tier。
- 读取某一 tier 不依赖前序 tier 的计算顺序。
- 调整数值时不会出现增量叠错。
- 测试可以直接断言每一 tier 的完整结果。

第一版硬性约束：

- 对每个相邻 tier，`next.damage > current.damage`。
- 对每个相邻 tier，`next.range_cells > current.range_cells`。
- `weapon_type`、`attack_type`、`damage_school`、`attack_pattern`、`targeting` 不随普通升级变化。
- `effects` 的类型、数量和 `status_type` 不随普通升级变化；只能调整已存在效果的数值字段。
- 如果某座塔 tier 1 没有溅射、减速、DoT 或连锁，普通升级不能新增这些机制。

### 升级不应改变的内容

线性升级中不建议改变这些玩家认知核心：

| 字段 | 规则 |
| --- | --- |
| `weapon_type` | 不变。弩塔升级后仍是弩塔。 |
| `attack_type` | 不变。穿刺塔升级后不应突然变成魔法攻击。 |
| `damage_school` | 不变。火焰塔升级后仍主要造成火焰伤害。 |
| `attack_pattern` | 不变。单体塔升级后不应变成溅射塔或连锁塔。 |
| `targeting` | 第一版不变。目标策略切换留给后续专门机制。 |
| `effects` 结构 | 不新增、不删除、不替换效果；只改已有效果的数值。 |

如果某个升级会把弩塔变成毒针塔、把炮塔变成火炮塔，应该作为未来“分支进化”处理，而不是普通 tier。

### 升级可以改变的内容

每座塔每次升级必须提升伤害和攻击范围。除此之外，可以选择一个副升级轴强化已有机制的数值，避免所有字段同时上涨。

| 字段 | 第一版规则 |
| --- | --- |
| `damage` | 必须严格提升。 |
| `range_cells` | 必须严格提升。 |
| `attack_interval` | 可选，数值降低表示攻速提升。 |
| `splash_radius_cells` | 可选，但只允许已有溅射塔提升。 |
| `status.duration_seconds` | 可选，但只允许已有状态延长持续时间。 |
| `status.tick_damage` | 可选，但只允许已有 DoT 提升 tick 伤害。 |
| `status.move_speed_multiplier` | 可选，但只允许已有减速强化倍率。 |
| `chain.max_targets` | 可选，但只允许已有连锁塔提升目标数量。 |
| `chain.damage_falloff` | 可选，但只允许已有连锁塔降低衰减。 |

### 冷却处理

升级不应重置当前攻击冷却，否则玩家可以通过升级获得一次额外瞬发攻击。建议规则是：

```text
new_cooldown_remaining = min(old_cooldown_remaining, new_tier.attack_interval)
```

含义：

- 升级不会让塔立即开火。
- 如果新 tier 攻击间隔更短，当前冷却不会超过新攻击间隔。
- 如果塔本来已经可以攻击，升级后仍可在下一次 tick 正常攻击。

这个规则需要在实现时补核心测试，覆盖“升级不清零冷却”和“升级后冷却被新间隔钳制”。

### 配置形状

当前 `game/data/towers/towers.json` 沿用 `tiers[n].upgrade_cost` 表示“从当前 tier 升到下一 tier 的费用”，并用 `effects[]` 表达每个 tier 的命中效果。未来如果加入分支升级，可扩展为：

```gdscript
{
  "id": "flame_tower",
  "display_name": "火焰塔",
  "short_name": "火",
  "build_cost": 30,
  "weapon_type": "SPELL",
  "attack_type": "MAGIC",
  "damage_school": "FIRE",
  "attack_pattern": "status_dot",
  "tiers": [
    {
      "tier": 1,
      "stats": {
        "damage": 4.0,
        "range_cells": 2.25,
        "attack_interval": 1.1,
        "targeting": "FIRST"
      },
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
          "stack_policy": "refresh"
        }
      ],
      "upgrade_to_next": {
        "cost": 45,
        "preview": "伤害、范围和灼烧数值提升"
      }
    },
    {
      "tier": 2,
      "stats": {
        "damage": 6.0,
        "range_cells": 2.35,
        "attack_interval": 1.05
      },
      "effects": [
        {
          "trigger": "on_hit",
          "type": "damage",
          "value": 6.0
        },
        {
          "trigger": "on_hit",
          "type": "apply_status",
          "status_type": "burn",
          "duration_seconds": 3.5,
          "tick_interval_seconds": 1.0,
          "tick_damage": 3.0,
          "stack_policy": "refresh"
        }
      ],
      "upgrade_to_next": {
        "cost": 80,
        "preview": "伤害、范围和灼烧数值再次提升"
      }
    },
    {
      "tier": 3,
      "stats": {
        "damage": 8.0,
        "range_cells": 2.5,
        "attack_interval": 1.0
      },
      "effects": [
        {
          "trigger": "on_hit",
          "type": "damage",
          "value": 8.0
        },
        {
          "trigger": "on_hit",
          "type": "apply_status",
          "status_type": "burn",
          "duration_seconds": 4.0,
          "tick_interval_seconds": 1.0,
          "tick_damage": 4.0,
          "stack_policy": "refresh"
        }
      ],
      "upgrade_to_next": null
    }
  ]
}
```

配置校验要求：

- `tiers` 不能为空。
- tier 编号从 1 连续递增。
- 非满级 tier 必须有正数升级费用。
- 满级不能配置普通 `upgrade_to_next.cost`。
- 每一 tier 必须有合法 stats。
- 每个相邻 tier 的 `damage` 和 `range_cells` 必须严格递增。
- 每一 tier 的 effects 必须能被当前 attack pattern 支持。
- 同一座塔的普通 tier 之间，effects 类型、数量和状态类型必须保持一致。
- UI preview 第一版由相邻 tier 的 `damage` 和 `range_cells` 差值生成，保证预览一定包含本版强制成长项。未来复杂状态、DoT 或连锁文案可以再补手写覆盖。

### UI 表达

当前右上浮动操作菜单保留。升级机制扩展后，菜单应展示：

- 塔名和当前 tier。
- 升级按钮和费用。
- 满级时显示 `Max tier` 或中文等价文案并禁用按钮。
- 金币不足时禁用按钮，并让状态栏提示缺少金币。
- 一行升级预览，必须包含伤害和范围，例如 `伤害 +2 / 范围 +0.1 / 灼烧 +1`。

未来如果加入分支进化，操作菜单可以把单个 Upgrade 按钮替换成多个升级选项按钮，但核心规则仍应走同一个 `try_upgrade_tower` 服务，只是请求参数从“tower id”扩展为“tower id + upgrade option id”。

### 初期塔升级方向

| 塔 | Tier 1 | Tier 2 | Tier 3 |
| --- | --- | --- | --- |
| 弩塔 | 穿刺单体，稳定点杀。 | 伤害和范围提升。 | 伤害、范围和攻速提升，继续专注单点。 |
| 炮塔 | 攻城物理，小范围溅射。 | 伤害、范围和溅射半径提升。 | 伤害、范围和溅射半径再次提升。 |
| 冰霜塔 | 魔法冰霜，造成小伤害并减速。 | 伤害、范围和减速持续时间提升。 | 伤害、范围提升，减速倍率小幅强化。 |
| 火焰塔 | 魔法火焰，命中后灼烧。 | 伤害、范围和灼烧 tick 伤害提升。 | 伤害、范围和灼烧持续时间提升；不新增小范围点燃。 |
| 毒针塔 | 穿刺毒素，命中后中毒。 | 伤害、范围和中毒持续时间提升。 | 伤害、范围和中毒 tick 伤害提升；不新增叠层。 |
| 雷霆塔 | 魔法闪电，已有连锁攻击。 | 伤害、范围和连锁数值提升。 | 伤害、范围和连锁衰减数值提升；不新增感电。 |

### 未来分支进化

线性 tier 满足近期 MVP，普通升级不做性质变化。长期如果需要性质变化，应在 max tier 或指定 tier 打开“分支进化”，并作为独立机制处理：

| 基础塔 | 分支方向 | 语义 |
| --- | --- | --- |
| 弩塔 | 长弓塔 | 更远射程和更慢高伤。 |
| 弩塔 | 毒针塔 | 保留穿刺武器，转为毒素 DoT。 |
| 炮塔 | 地震塔 | 从一次溅射转为地面持续区域。 |
| 冰霜塔 | 冰封塔 | 更强控制，可能引入冻结。 |
| 火焰塔 | 炼狱塔 | 更强火焰 DoT 或地面火。 |
| 雷霆塔 | 风暴塔 | 从连锁变成大范围随机落雷。 |

分支进化需要额外字段：

```gdscript
"upgrade_options": [
  {
    "id": "venom_branch",
    "from_tier": 3,
    "target_tower_id": "venom_tower",
    "target_tier": 1,
    "cost": 120,
    "preview": "转化为毒素持续伤害塔"
  }
]
```

短期不实现这个字段；普通升级只做数值提升。

### 第一版实现状态

当前第一版已实现：

- `TowerConfig` 校验默认和自定义 tier 配置，要求每次升级都严格提升 `damage` 和 `range_cells`。
- `TowerConfig` 校验普通升级不能给原本没有溅射或减速的塔新增这类机制。
- `TowerConfig.get_upgrade_preview()` 生成包含伤害和范围成长的升级预览。
- `check-assets.sh` 校验 `towers.json` 的 schema、非满级升级费用、满级无升级费用、tier 成长和 effect 语义。
- `TowerPlacementService.try_upgrade_tower()` 升级后不会清空冷却，并会把剩余冷却钳制到新 tier 的攻击间隔。
- 塔操作菜单显示升级预览，并继续显示升级费用、满级、拆除返还和禁用状态。

### 测试要求

核心 GUT：

- `test_tower_config.gd` 覆盖每座塔的 max tier、升级费用、tier stats 和升级预览。
- `test_tower_config.gd` 覆盖每个相邻 tier 的 `damage` 和 `range_cells` 都严格递增。
- `test_tower_config.gd` 覆盖普通升级不会新增溅射或减速机制。
- `test_tower_config.gd` 覆盖非法配置：伤害或范围未递增、普通升级新增溅射或减速。
- `test_tower_placement_service.gd` 覆盖升级成功、金币不足、满级、缺失塔和升级失败不变更状态。
- `test_tower_placement_service.gd` 覆盖 `invested_gold` 累加和拆除返还。
- `test_tower_placement_service.gd` 覆盖升级后 cooldown 不清零，并按新攻击间隔钳制。
- `test_tower_attack_service.gd` 覆盖升级后攻击读取新 tier 的 damage、range、attack_interval、splash、status、DoT 或 chain 数值。
- `test_projectile_service.gd` 和后续状态测试覆盖升级后的同类 effects 会使用新数值产生命中、状态和 tick 事件。

场景和 smoke：

- `test_main_scene.gd` 覆盖操作菜单中的费用、金币不足禁用、升级预览和快捷键 `U`。
- `check-ui-smoke.sh` 保留塔操作菜单截图，并覆盖升级后 tier badge 和按钮状态。
- `check-gameplay-smoke.sh` 保留升级/拆除返还 scenario，并在新增火焰、毒针、雷霆后加入代表性升级 checkpoint。

数据化后：

- 新增逐塔 fixture，验证数据文件能加载为更正式的 `TowerDefinition`/Resource 结构。
- gameplay smoke trace 记录 tower id、tier、upgrade cost、invested gold 和 refund。

## 替代方案

- 让 Tier 3 做机制质变。可玩性更强，但会同时扩大配置、UI、素材和测试矩阵；第一版先不做。
- 不强制每次升级提升范围。数值更容易平衡，但升级反馈不稳定，玩家可能感觉某些升级只是在买隐藏参数。
- 立即做分支升级。可玩性更强，但会同时放大 UI、配置、素材和测试矩阵，不适合当前阶段。
- 回到两塔合成升级。未来可以配合随机召唤和格子压力再评估，但近期和直接升级的玩家感知差异不足。
- 升级时重置冷却。手感更爽，但会变成可利用的瞬发攻击，不利于确定性平衡。

## 风险

- 配置字段扩展太快会让 `TowerConfig` 变复杂，需要先按火焰 DoT 和雷霆连锁的真实需求推进。
- 每次升级都提升范围，可能让高 tier 塔覆盖过大，需要给不同塔设置小而可控的范围增量。
- 只做数值提升会降低单次升级的新鲜感，需要通过伤害、范围和塔特色数值让反馈足够明显。
- 升级预览第一版只自动生成伤害和范围；未来如果展示状态、DoT、连锁等非必选字段，需要避免漏掉关键变化。
- 后续分支进化会影响操作菜单尺寸，移动横屏需要重新做 UI smoke 审查。

## 开放问题

- 第一版新塔是否全部 3 级，还是弩塔、炮塔、冰霜塔先 3 级，新塔先 2 级。
- 每种塔的范围成长上限是多少，避免高 tier 后覆盖过度。
- 每座塔除伤害和范围外，第一版是否只允许一个副数值成长轴。
- 毒针塔叠层、火焰小范围点燃和雷霆感电都延后到分支或后续机制，具体进入哪个版本仍待决定。
- 未来复杂效果的升级预览是继续扩展结构化 diff，还是允许每个 tier 手写补充文案。
