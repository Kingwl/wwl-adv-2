# 设计：攻击、防御、伤害类型体系

## 状态

Implemented

## 背景

当前 prototype 已有 Single、Area、Slow 三类塔，但塔的差异主要来自攻击模式、数值和状态效果。进入 MVP 内容扩展后，需要一套能支撑更多塔、敌人和波次的克制体系。

本设计参考 Warcraft III 的攻击类型与护甲类型克制思路，但不直接复制完整规则。项目采用塔防化的三层模型：

- 武器形态决定攻击类型。
- 防御类型决定武器克制。
- 怪物种族决定冰、火、毒、电等伤害类型抗性。

## 目标

- 让玩家能通过“武器形态 + 元素附加 + 敌人外观/种族”理解克制关系。
- 让数值系统可以数据化到塔、敌人和波次配置。
- 避免把攻击类型、防御类型和伤害类型做成难维护的三维倍率表。
- 支持正抗性和负抗性，允许敌人对某些伤害类型减伤或增伤。
- 保持第一版实现足够小，可以先接入现有四塔和基础敌人。

## 非目标

- 第一版不实现完整 Warcraft III 护甲值减伤公式。
- 第一版不实现完全免疫、吸收伤害或元素反应。
- 第一版不要求所有伤害类型都有对应塔和视觉资产。
- 第一版不做复杂状态叠层规则，只定义体系边界。

## 方案

### 三层模型

```text
weapon_type   -> 推导 attack_type
attack_type   -> 对 armor_type 查固定倍率
damage_school -> 对 race_type 查正/负抗性
```

最终伤害公式：

```text
final_damage =
  base_damage
  * attack_vs_armor_multiplier
  * (1 - race_school_resistance)
  * other_modifiers
```

抗性语义：

| 抗性 | 实际倍率 | 含义 |
| ---: | ---: | --- |
| `0.50` | `0.50x` | 强抗 |
| `0.25` | `0.75x` | 抗性 |
| `0.00` | `1.00x` | 正常 |
| `-0.25` | `1.25x` | 弱点 |
| `-0.50` | `1.50x` | 强弱点 |

第一版建议把抗性限制在 `0.50` 到 `-0.50` 之间。免疫可以后续单独加，不用普通抗性隐式表达。

### 攻击类型

攻击类型表达武器打护甲的克制关系。它不直接表达冰、火、毒、电。

| 攻击类型 | 英文枚举 | 来源/武器形态 | 主要克制 | 主要弱点 | 设计用途 |
| --- | --- | --- | --- | --- | --- |
| 普通攻击 | `NORMAL` | 近战、旋刃、守卫塔 | 中甲 | 城甲 | 稳定基础输出 |
| 穿刺攻击 | `PIERCE` | 弓、弩、标枪、针刺 | 无甲、轻甲 | 城甲、英雄甲 | 打快怪、脆皮、飞行怪 |
| 攻城攻击 | `SIEGE` | 炮、投石、爆弹 | 城甲、无甲 | 轻甲、中甲、英雄甲 | 打构装、建筑型、群怪 |
| 魔法攻击 | `MAGIC` | 法杖、符文、元素法术 | 重甲、轻甲 | 城甲、英雄甲 | 元素塔、控制塔 |
| 英雄攻击 | `HERO` | 高级/传奇塔 | 通用，偏打精英 | 城甲 | 后期稳定输出 |
| 混乱攻击 | `CHAOS` | 终局/特殊塔 | 全类型稳定 | 成本高、稀有 | 稀有塔或最终升级 |

### 防御类型

防御类型表达敌人的护甲、体型和战斗职责。

| 防御类型 | 英文枚举 | 典型敌人 | 被克制 | 抗性倾向 |
| --- | --- | --- | --- | --- |
| 无甲 | `UNARMORED` | 法师、小型虫群、脆皮怪 | 穿刺、攻城 | 通常血少，怕爆发 |
| 轻甲 | `LIGHT` | 快速怪、飞行怪、侦察怪 | 穿刺、魔法 | 抗普通一般，怕集火 |
| 中甲 | `MEDIUM` | 普通士兵、兽人、步兵 | 普通 | 泛用基础敌人 |
| 重甲 | `HEAVY` | 大型兽、骑士、蛮兵 | 魔法 | 抗穿刺，血量高 |
| 城甲 | `FORTIFIED` | 构装、机械、攻城兽、护盾怪 | 攻城 | 强抗穿刺、魔法、普通 |
| 英雄甲 | `HERO` | 精英、Boss、小 Boss | 英雄、混乱 | 抗穿刺、攻城、魔法 |

### 攻击 vs 防御倍率

| 攻击 \ 防御 | 无甲 | 轻甲 | 中甲 | 重甲 | 城甲 | 英雄甲 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 普通 | 1.00 | 1.00 | 1.50 | 1.00 | 0.70 | 1.00 |
| 穿刺 | 1.50 | 2.00 | 0.75 | 1.00 | 0.35 | 0.50 |
| 攻城 | 1.50 | 0.50 | 0.50 | 1.00 | 1.50 | 0.50 |
| 魔法 | 1.00 | 1.25 | 0.75 | 2.00 | 0.35 | 0.50 |
| 英雄 | 1.00 | 1.00 | 1.00 | 1.00 | 0.50 | 1.00 |
| 混乱 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

### 武器形态

玩家更容易理解武器形态，而不是直接理解攻击类型。配置层可以显式写 `weapon_type`，由系统推导默认 `attack_type`。

| 武器形态 | 英文枚举 | 默认攻击类型 | 例子 | 玩法语义 |
| --- | --- | --- | --- | --- |
| 弓 | `BOW` | 穿刺 | 弓塔 | 快速、便宜、打轻甲和无甲 |
| 弩 | `CROSSBOW` | 穿刺 | 弩塔、冰弩塔 | 慢一点，单发更高 |
| 炮 | `CANNON` | 攻城 | 炮塔、火炮塔 | 溅射、打城甲和群怪 |
| 刃 | `BLADE` | 普通 | 旋刃塔、守卫塔 | 稳定克中甲 |
| 法术 | `SPELL` | 魔法 | 冰法、火法、电法 | 元素状态和重甲克制 |
| 英雄 | `HEROIC` | 英雄 | 传奇塔 | 打精英和 Boss |
| 混乱 | `CHAOS` | 混乱 | 终局塔 | 稳定全类型输出 |

如果个别塔需要打破默认关系，可以显式覆盖 `attack_type`，但第一版应尽量避免。

### 伤害类型

伤害类型表达元素或流派，不负责武器护甲克制。

| 伤害类型 | 英文枚举 | 主要效果 | 适合搭配 |
| --- | --- | --- | --- |
| 物理 | `PHYSICAL` | 无元素附加，稳定可靠 | 普通、穿刺、攻城 |
| 冰霜 | `FROST` | 减速，后续可做冻结 | 魔法、穿刺 |
| 火焰 | `FIRE` | 灼烧 DoT，压高血量 | 魔法、攻城 |
| 毒素 | `POISON` | 中毒 DoT，可叠层 | 穿刺、魔法 |
| 闪电 | `LIGHTNING` | 连锁、跳跃、多目标 | 魔法 |
| 奥术 | `ARCANE` | 穿抗、稳定后期伤害 | 魔法、英雄 |
| 暗影 | `SHADOW` | 易伤、削弱、减益 | 魔法，后期再加 |

第一版实现建议只接入 `PHYSICAL`、`FROST`、`FIRE`、`POISON`、`LIGHTNING`。`ARCANE` 和 `SHADOW` 留给高级塔。

### 怪物种族

抗性属于怪物种族，而不是单个防御类型。防御类型解决武器克制，种族解决元素克制。

| 种族 | 英文枚举 | 抗性主题 |
| --- | --- | --- |
| 野兽 | `BEAST` | 低抗性，作为基础种族 |
| 人形 | `HUMANOID` | 均衡，无明显元素弱点 |
| 亡灵 | `UNDEAD` | 抗毒，怕火和奥术 |
| 构装 | `CONSTRUCT` | 抗毒，怕闪电，通常配城甲 |
| 火元素 | `ELEMENTAL_FIRE` | 抗火，怕冰 |
| 冰元素 | `ELEMENTAL_FROST` | 抗冰，怕火 |
| 植物 | `PLANT` | 抗毒，怕火 |
| 恶魔 | `DEMON` | 抗火和毒，怕奥术 |

第一版建议先做：野兽、人形、亡灵、构装、火元素、冰元素。

### 种族抗性表

| 种族 \ 伤害类型 | 物理 | 冰霜 | 火焰 | 毒素 | 闪电 | 奥术 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 野兽 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 人形 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 亡灵 | 0.00 | 0.00 | -0.25 | 0.50 | 0.00 | -0.25 |
| 构装 | 0.10 | 0.00 | 0.00 | 0.75 | -0.50 | 0.00 |
| 火元素 | 0.00 | -0.50 | 0.50 | 0.25 | 0.00 | 0.00 |
| 冰元素 | 0.00 | 0.50 | -0.50 | 0.25 | 0.00 | 0.00 |
| 植物 | 0.00 | 0.00 | -0.50 | 0.50 | 0.00 | 0.00 |
| 恶魔 | 0.00 | 0.00 | 0.25 | 0.25 | 0.00 | -0.25 |

注意：构装的毒素抗性 `0.75` 会让毒素伤害变为 `0.25x`，这是强抗特例。实现时可以先允许，但平衡上要谨慎使用。

### 当前四塔映射

| 当前塔 | 武器形态 | 攻击类型 | 伤害类型 | 说明 |
| --- | --- | --- | --- | --- |
| Single | `BOW` 或 `CROSSBOW` | `PIERCE` | `PHYSICAL` | 便宜快攻，打轻甲和无甲 |
| Area | `CANNON` | `SIEGE` | `PHYSICAL` 或 `FIRE` | 溅射清群，打城甲 |
| Slow | `SPELL` | `MAGIC` | `FROST` | 克重甲，附带减速 |
| Flame | `SPELL` | `MAGIC` | `FIRE` | 克怕火种族，附带灼烧 DoT |

### 后续塔例子

| 塔 | 武器形态 | 攻击类型 | 伤害类型 | 攻击模式 |
| --- | --- | --- | --- | --- |
| 冰弩塔 | `CROSSBOW` | `PIERCE` | `FROST` | 单体，附带减速 |
| 火炮塔 | `CANNON` | `SIEGE` | `FIRE` | 溅射，附带燃烧 |
| 毒针塔 | `CROSSBOW` | `PIERCE` | `POISON` | 单体或多段，中毒 |
| 雷法塔 | `SPELL` | `MAGIC` | `LIGHTNING` | 连锁 |
| 奥术塔 | `HEROIC` | `HERO` | `ARCANE` | 后期打精英/Boss |
| 混乱塔 | `CHAOS` | `CHAOS` | `ARCANE` 或 `SHADOW` | 终局稳定输出 |

### 数据形状草案

塔配置：

```gdscript
{
  "id": "frost_crossbow",
  "weapon_type": "CROSSBOW",
  "damage_school": "FROST",
  "attack_pattern": "single",
  "status_effects": ["slow"],
  "tiers": [
    {
      "damage": 10.0,
      "range_cells": 2.5,
      "attack_interval": 1.0,
      "upgrade_cost": 40
    }
  ]
}
```

敌人配置：

```gdscript
{
  "id": "undead_brute",
  "armor_type": "HEAVY",
  "race_type": "UNDEAD",
  "health": 40.0,
  "speed_cells_per_second": 0.8,
  "reward_gold": 7
}
```

种族抗性配置：

```gdscript
{
  "UNDEAD": {
    "PHYSICAL": 0.0,
    "FROST": 0.0,
    "FIRE": -0.25,
    "POISON": 0.5,
    "LIGHTNING": 0.0,
    "ARCANE": -0.25
  }
}
```

特殊敌人可以有 override：

```gdscript
{
  "race_type": "UNDEAD",
  "school_resistance_overrides": {
    "FIRE": -0.50
  }
}
```

### 计算例子

亡灵重甲怪被火法塔攻击：

```text
base_damage = 10
attack_type = MAGIC
armor_type = HEAVY
MAGIC vs HEAVY = 2.0
race_type = UNDEAD
FIRE resistance = -0.25
school multiplier = 1.25

final_damage = 10 * 2.0 * 1.25 = 25
```

### 第一版实现状态

当前第一版已实现：

- `DamageTypes` 定义武器形态、攻击类型、防御类型、伤害类型、种族和攻击模式枚举。
- `DamageAffinityConfig` 实现武器到攻击类型推导、攻击类型对防御类型倍率表、种族对伤害类型的正/负抗性表，以及最终伤害公式。
- `Enemy` 增加 `armor_type`、`race_type` 和 `school_resistance_overrides`。
- `DamageEvent` 携带 `attack_type` 和 `damage_school`。
- `EnemyDamageService` 在应用伤害前按攻击/防御/伤害/种族公式计算最终伤害。
- `TowerConfig` 从 `game/data/towers/towers.json` 给现有四塔提供类型元数据：Single = CROSSBOW/PIERCE/PHYSICAL，Area = CANNON/SIEGE/PHYSICAL，Slow = SPELL/MAGIC/FROST，Flame = SPELL/MAGIC/FIRE。
- `TowerAttackService` 和 `ProjectileService` 将塔的攻击类型和伤害类型传递到投射物与伤害事件。
- `check-assets.sh` 已校验塔配置 schema 中的攻击类型、伤害类型、攻击模式和 effect 字段。

第一版尚未实现：

- 敌人和波次的数据文件 schema。
- 多敌人类型和波次配置中的 armor/race 分布。
- UI 中展示克制关系或敌人抗性。

构装城甲怪被毒针塔攻击：

```text
base_damage = 10
attack_type = PIERCE
armor_type = FORTIFIED
PIERCE vs FORTIFIED = 0.35
race_type = CONSTRUCT
POISON resistance = 0.75
school multiplier = 0.25

final_damage = 10 * 0.35 * 0.25 = 0.875
```

## 实现计划

1. 新增核心枚举或配置常量：`WeaponType`、`AttackType`、`ArmorType`、`DamageSchool`、`RaceType`。
2. 给现有塔 stats 增加 `weapon_type`、`attack_type`、`damage_school`。
3. 给敌人增加 `armor_type`、`race_type`。
4. 新增 `DamageAffinityConfig` 或同类服务，负责攻击/防御倍率和种族抗性查表。
5. 让 projectile 或 damage event 携带 `attack_type` 和 `damage_school`。
6. 在 `EnemyDamageService` 中使用新公式结算最终伤害。
7. 把敌人、种族抗性和波次迁移到数据文件，并补 schema。

## 测试要求

- `test_damage_affinity_config.gd` 覆盖攻击/防御倍率表、种族抗性、默认值和负抗性。
- `test_enemy_damage_service.gd` 覆盖最终伤害公式。
- `test_tower_config.gd` 覆盖现有四塔的武器形态、攻击类型和伤害类型。
- `test_projectile_service.gd` 覆盖 projectile 携带并传递攻击/伤害类型。
- 数据化后 `check-assets.sh` 必须继续校验 tower/enemy/race resistance 的枚举值和必填字段；当前已覆盖 tower。
- Gameplay smoke 后续增加一个克制场景，例如火焰打亡灵、毒素打构装的伤害摘要。

## 替代方案

- 只保留攻击类型和防御类型，不做伤害类型。问题是冰、火、毒、电只能通过状态效果表达，无法形成清晰的种族弱点。
- 做 `攻击类型 × 防御类型 × 伤害类型` 三维表。问题是 6 个攻击类型、6 个防御类型、7 个伤害类型会形成 252 个倍率，难以维护和测试。
- 把抗性放在单个敌人身上。问题是每个敌人都要重复配置元素抗性，难以形成“亡灵怕火、构装怕电”这种可读规则。

## 风险

- 两段倍率相乘后可能产生过高爆发，尤其是 `2.0x` 护甲克制再叠 `1.5x` 元素弱点。
- 玩家需要 UI 提示才能理解双层克制，否则会觉得伤害波动不透明。
- 如果第一版就加入免疫或吸收，可能导致玩家阵容错误时关卡不可解。
- 种族抗性和状态抗性容易混淆。火焰伤害增伤不一定意味着燃烧状态更强，后续要分开定义。

## 开放问题

- 当前 `Area` 塔第一版应保持 `PHYSICAL`，还是改为 `FIRE` 来更早展示伤害类型？
- 是否需要为飞行怪单独做防御类型，还是先用 `LIGHT` 表达？
- Boss 是否统一使用 `HERO` 防御类型，还是按种族保留不同护甲？
- 伤害结果是否需要在 UI 中显示克制提示，例如 `Weak`、`Resist`、`Critical` 一类浮字？
