# 核心玩法功能

这个文档记录当前玩家能接触到的核心玩法功能，以及对应的规则所有权和测试覆盖。

## 功能清单

| 功能 | 玩家语义 | 核心所有权 | 当前自动化 | 状态和缺口 |
| --- | --- | --- | --- | --- |
| 棋盘格和路径 | 玩家只能在可建造格放塔，敌人沿关卡路径移动。 | `game/scripts/core/board/`、`game/scripts/core/maps/`、`game/scripts/core/movement/` | `test_board_placement.gd`、`test_path_validation.gd`、`test_path_follower.gd`、`test_map_definitions.gd` | 已覆盖基础规则。后续多地图和动态路径需要扩展 map fixture。 |
| 塔放置和费用 | 选择塔后点击可建造格，金币足够时生成塔并扣费。 | `game/scripts/core/placement/`、`game/scripts/core/economy/`、`game/scripts/core/towers/` | `test_tower_placement_service.gd`、`test_wallet.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖成功、失败和金币不足。UI 可触达路径由场景测试、UI smoke 和 gameplay smoke 覆盖。 |
| 三种基础塔 | Single、Area、Slow 共享放置流程，但攻击和投射物效果不同。 | `tower_config.gd`、`tower_stats.gd`、`tower_attack_service.gd`、`projectile_service.gd` | `test_tower_config.gd`、`test_tower_attack_service.gd`、`test_projectile_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖基础差异和代表视觉 checkpoint。数值仍部分硬编码，迁移到数据文件后需补 schema 和数值测试。 |
| 塔注册表 | 放置后的塔进入注册表，战斗系统按注册表状态执行。 | `tower_registry.gd`、`tower.gd`、`tower_placement_service.gd` | `test_tower_registry.gd`、`test_tower_placement_service.gd`、`test_main_scene.gd` | 已覆盖注册、查询和场景接线。 |
| 塔成长/合成 | 同类型、同等级塔可以在核心层合成。玩家侧合成或升级交互尚未定案。 | `tower_merge_service.gd`、`tower_merge_result.gd` | `test_tower_merge_service.gd` | 核心层已覆盖，玩家可触达流程仍是开放决策。 |
| 目标选择 | 塔优先攻击范围内路径进度最靠前的有效敌人。 | `targeting_service.gd` | `test_targeting_service.gd` | 已覆盖无目标、完成、击败和射程外。后续多策略目标选择需要新增测试矩阵。 |
| 攻击冷却和发射 | 固定 tick 中，冷却结束且有目标时生成攻击结果和投射物。 | `tower_attack_service.gd`、`combat_simulation.gd` | `test_tower_attack_service.gd`、`test_combat_simulation.gd`、`test_main_scene.gd` | 已覆盖基础固定 tick 流程。更复杂 buff/debuff 需要确定性回归用例。 |
| 投射物命中 | 投射物移动到目标后造成伤害；Area 可溅射，Slow 可施加减速状态。 | `projectile_service.gd`、`combat_projectile.gd`、`status_event.gd` | `test_projectile_service.gd`、`test_combat_simulation.gd`、`check-gameplay-smoke.sh` | 已覆盖命中、未命中、范围和减速。Gameplay smoke 覆盖 Single projectile、Area splash 和 Slow impact 的视觉 checkpoint。 |
| 敌人生命和死亡 | 敌人受伤、死亡，死亡事件只能产生一次。 | `enemy.gd`、`enemy_damage_service.gd`、`enemy_death_event.gd` | `test_enemy_damage_service.gd`、`test_combat_simulation.gd` | 已覆盖基础生命周期。后续敌人类型扩展后需要按类型补 fixture。 |
| 击杀和清波奖励 | 击杀敌人和清空波次时给玩家金币。 | `kill_reward_service.gd`、`wave_reward_service.gd`、`wallet.gd` | `test_kill_reward_service.gd`、`test_wave_reward_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖奖励交易、HUD 集成和代表视觉反馈。 |
| 漏怪、生命和失败 | 敌人走到路径终点会扣生命；生命归零失败。 | `enemy_leak_service.gd`、`player_life.gd`、`combat_simulation.gd` | `test_enemy_leak_service.gd`、`test_player_life.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖漏怪、去重、生命钳制、失败和代表视觉反馈。 |
| 波次和胜利 | 按波次定义生成敌人；全部波次清空且玩家存活时胜利。 | `wave_spawner.gd`、`wave_definition.gd`、`wave_state.gd`、`combat_simulation.gd` | `test_wave_spawner.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 已覆盖 prototype 三波流程和清波胜利视觉 checkpoint。MVP 长波次和平衡仍未覆盖。 |
| 关卡和地图数据 | 关卡路径和地图 style 从 `game/data/` 加载。 | `level_definition.gd`、`map_style_definition.gd`、`game/tools/check-assets.sh` | `test_map_definitions.gd`、`check-assets.sh` | 已有 schema 校验。塔、敌人和波次配置仍待数据化。 |
| 场景玩法集成 | 开始游戏、暂停、重开、放塔、战斗推进、胜利和失败都能从主场景触发。 | `game/scripts/board/board_view.gd`、`game/scripts/start_screen.gd` | `test_main_scene.gd`、`check-ui-smoke.sh`、`check-gameplay-smoke.sh` | 已覆盖主要集成路径和代表性 gameplay scenario。`BoardView` 职责偏大，是后续拆分风险。 |

## 当前主要玩法缺口

- 塔成长模型还未决定：玩家侧合成交互，还是直接升级。
- 塔、敌人和波次数值尚未完全迁移到数据文件。
- 自动化已有代表性 gameplay smoke，但仍缺长局 playable run：例如多波次、多塔类型、多次放置、奖励、漏怪、胜负的端到端机器可读摘要。
- 当前测试关注规则正确性和集成路径，不覆盖数值平衡质量。
