# 核心玩法功能

这个文档记录当前玩家能接触到的核心玩法功能，以及对应的规则所有权和测试覆盖。

## 功能清单

| 功能 | 玩家语义 | 核心所有权 | 当前自动化 | 状态和缺口 |
| --- | --- | --- | --- | --- |
| 棋盘格和路径 | 玩家只能在可建造格放塔，敌人沿关卡路径移动。 | `game/scripts/core/board/`、`game/scripts/core/maps/`、`game/scripts/core/movement/` | `test_board_placement.gd`、`test_path_validation.gd`、`test_path_follower.gd`、`test_map_definitions.gd` | 已覆盖基础规则。后续多地图和动态路径需要扩展 map fixture。 |
| 塔放置和费用 | 选择塔后点击可建造格，金币足够时生成塔并扣费。 | `game/scripts/core/placement/`、`game/scripts/core/economy/`、`game/scripts/core/towers/` | `test_tower_placement_service.gd`、`test_wallet.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖成功、失败、金币不足和初始投入记录。UI 可触达路径由场景测试、UI smoke 和 gameplay smoke 覆盖。 |
| 四种基础塔 | Single、Area、Slow、Flame 共享放置流程，但攻击、投射物效果、状态效果和升级曲线不同。 | `game/data/towers/towers.json`、`tower_config.gd`、`tower_stats.gd`、`tower_attack_service.gd`、`projectile_service.gd` | `test_tower_config.gd`、`test_tower_attack_service.gd`、`test_projectile_service.gd`、`test_main_scene.gd`、`check-assets.sh`、`check-gameplay-smoke.sh` | 已覆盖 JSON 加载、schema/语义校验、基础差异、分塔升级曲线、升级后攻击读取 tier stats 和代表视觉 checkpoint。新增塔应先进入 `towers.json`，再补素材、机制测试和视觉 smoke。 |
| 伤害克制体系 | 塔攻击带有武器形态、攻击类型和伤害类型；敌人带有防御类型和种族；最终伤害按攻击/防御倍率和种族抗性结算。 | `damage_types.gd`、`damage_affinity_config.gd`、`damage_event.gd`、`enemy.gd`、`enemy_damage_service.gd`、`tower_config.gd` | `test_damage_affinity_config.gd`、`test_enemy_damage_service.gd`、`test_tower_config.gd`、`test_tower_attack_service.gd`、`test_projectile_service.gd` | 已覆盖武器到攻击类型推导、攻击/防御倍率、正负种族抗性、override、现有四塔类型映射、投射物携带类型和最终伤害结算。敌人和塔数据文件、UI 展示和多敌人类型波次仍待补。 |
| 状态和 DoT | 命中效果可以给敌人施加状态；减速会降低移动速度；火焰塔会施加灼烧；灼烧/中毒可按完整 tick interval 产生 DoT 伤害，并继续走伤害克制体系。 | `status_event.gd`、`status_effect.gd`、`status_effect_service.gd`、`enemy.gd`、`path_follower.gd`、`combat_simulation.gd`、`tower_effect.gd` | `test_status_effect_service.gd`、`test_path_follower.gd`、`test_combat_simulation.gd`、`test_projectile_service.gd`、`test_tower_config.gd`、`check-gameplay-smoke.sh` | 已覆盖 `effects[]` 中的即时伤害、溅射伤害、附加状态、slow 取最强并刷新、refresh 类 DoT 不叠层、DoT 延迟到完整 interval 才生效、DoT 伤害携带攻击/伤害类型并走最终伤害结算、慢速状态实际影响移动、Flame 施加 Burn 并产生后续 DoT。毒针塔、独立视觉事件、状态 UI 仍待补。 |
| 塔注册表 | 放置后的塔进入注册表，战斗系统按注册表状态执行。 | `tower_registry.gd`、`tower.gd`、`tower_placement_service.gd` | `test_tower_registry.gd`、`test_tower_placement_service.gd`、`test_main_scene.gd` | 已覆盖注册、查询和场景接线。 |
| 塔成长/拆除 | 点击已放置塔显示操作菜单；升级消耗金币并提升 tier；普通升级只做数值提升，每次升级都提升伤害和攻击范围；拆除返还 50% 建造和升级累计投入。核心合成服务保留为未来随机召唤/合成经济参考。 | `game/data/towers/towers.json`、`tower_config.gd`、`tower_placement_service.gd`、`tower_upgrade_result.gd`、`tower_removal_result.gd`、`tower_merge_service.gd` | `test_tower_config.gd`、`test_tower_placement_service.gd`、`test_board_game_session.gd`、`test_main_scene.gd`、`check-assets.sh`、`check-ui-smoke.sh`、`check-gameplay-smoke.sh` | 已覆盖数据文件升级配置、每次升级伤害/范围递增、禁止升级新增溅射/减速机制、升级预览、升级冷却钳制、结构化失败、session/combat towers 同步、金币不足、满级、累计投入返还、菜单按钮和关闭状态。 |
| 目标选择 | 塔优先攻击范围内路径进度最靠前的有效敌人。 | `targeting_service.gd` | `test_targeting_service.gd` | 已覆盖无目标、完成、击败和射程外。后续多策略目标选择需要新增测试矩阵。 |
| 攻击冷却和发射 | 固定 tick 中，冷却结束且有目标时生成攻击结果和投射物。 | `tower_attack_service.gd`、`combat_simulation.gd` | `test_tower_attack_service.gd`、`test_combat_simulation.gd`、`test_main_scene.gd` | 已覆盖基础固定 tick 流程。更复杂 buff/debuff 需要确定性回归用例。 |
| 投射物命中 | 投射物移动到目标后按 `effects[]` 造成伤害或状态：Single 单体伤害，Area 溅射，Slow 减速，Flame 灼烧 DoT。 | `projectile_service.gd`、`combat_projectile.gd`、`tower_effect.gd`、`status_event.gd` | `test_projectile_service.gd`、`test_combat_simulation.gd`、`check-gameplay-smoke.sh` | 已覆盖命中、未命中、effect 驱动的单体/溅射/状态、减速状态事件、灼烧状态事件、状态携带攻击/伤害类型和慢速/DoT 后续影响。Gameplay smoke 覆盖 Single projectile、Area splash、Slow impact 和 Flame burn 的视觉 checkpoint。 |
| 敌人生命和死亡 | 敌人受伤、死亡，死亡事件只能产生一次。 | `enemy.gd`、`enemy_damage_service.gd`、`enemy_death_event.gd` | `test_enemy_damage_service.gd`、`test_combat_simulation.gd` | 已覆盖基础生命周期。后续敌人类型扩展后需要按类型补 fixture。 |
| 击杀和清波奖励 | 击杀敌人和清空波次时给玩家金币。 | `kill_reward_service.gd`、`wave_reward_service.gd`、`wallet.gd` | `test_kill_reward_service.gd`、`test_wave_reward_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖奖励交易、HUD 集成和代表视觉反馈。 |
| 漏怪、生命和失败 | 敌人走到路径终点会扣生命；生命归零失败。 | `enemy_leak_service.gd`、`player_life.gd`、`combat_simulation.gd` | `test_enemy_leak_service.gd`、`test_player_life.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖漏怪、去重、生命钳制、失败和代表视觉反馈。 |
| 波次和胜利 | 按波次定义生成敌人；全部波次清空且玩家存活时胜利。 | `wave_spawner.gd`、`wave_definition.gd`、`wave_state.gd`、`combat_simulation.gd` | `test_wave_spawner.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖 prototype 三波流程和清波胜利视觉 checkpoint。MVP 长波次和平衡仍未覆盖。 |
| 关卡、地图和塔数据 | 关卡路径、地图 style 和塔定义从 `game/data/` 加载。 | `level_definition.gd`、`map_style_definition.gd`、`tower_config.gd`、`game/tools/check-assets.sh` | `test_map_definitions.gd`、`test_tower_config.gd`、`check-assets.sh` | 已有关卡、map style 和塔配置 schema 校验。敌人和波次配置仍待数据化。 |
| 场景玩法集成 | 开始游戏、暂停、重开、放塔、战斗推进、胜利和失败都能从主场景触发。 | `game/scripts/board/board_view.gd`、`game/scripts/start_screen.gd` | `test_main_scene.gd`、`check-ui-smoke.sh`、`check-gameplay-smoke.sh` | 已覆盖主要集成路径和代表性 gameplay scenario。`BoardView` 职责偏大，是后续拆分风险。 |

## 当前主要玩法缺口

- 敌人和波次数值尚未迁移到数据文件。
- 通用状态/DoT、`effects[]` 和火焰塔已进入核心规则和玩家可见路径，但毒针塔、雷霆塔、独立视觉事件和状态图标尚未接入。
- 自动化已有代表性 gameplay smoke，但仍缺长局 playable run：例如多波次、多塔类型、多次放置、奖励、漏怪、胜负的端到端机器可读摘要。
- 当前测试关注规则正确性和集成路径，不覆盖数值平衡质量。
