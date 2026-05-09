# 核心玩法测试计划

这个测试计划把核心玩法功能映射到自动化证据。它补充 `docs/testing/prototype-rule-coverage.md`，后者保留更短的覆盖 checklist。

## 测试层级

- 核心 GUT：验证 `game/scripts/core/` 中的确定性规则，不依赖场景节点、渲染、输入坐标或帧时间。
- 场景 GUT：验证主场景能把输入、HUD、资源、暂停、胜利、失败和核心服务正确接线。
- Native smoke：验证玩家路径可以在 Godot native runtime 中启动、进入主场景、放置一座塔并产出截图和 UI 审查材料。
- Gameplay smoke：验证代表性玩法 scenario 的 trace，并产出整屏截图、board crop 和状态 overlay。它验证玩家能看见关键玩法结果，不替代核心规则 GUT。
- 资产/schema 检查：验证 `game/data/levels` 和 `game/data/map_styles` 的结构。

## 功能测试矩阵

| ID | 功能 | 必测场景 | 自动化位置 | 证据 | 仍缺什么 |
| --- | --- | --- | --- | --- | --- |
| GP-BOARD-001 | 棋盘放置 | 空可建造格成功；越界、路径、阻挡、锁定、占用、保留格失败；移除成功和失败。 | `test_board_placement.gd` | GUT 断言结构化 `PlacementResult` / `RemovalResult`。 | 多地图 fixture 覆盖。 |
| GP-PATH-001 | 路径校验和敌人移动 | 路径过短、越界、非路径、对角和跳跃失败；合法路径通过；敌人按 delta 沿路径移动并在终点完成。 | `test_path_validation.gd`、`test_path_follower.gd` | GUT 断言网格位置、path distance、completed/defeated 状态。 | 复杂路径和多关卡路径 fixture。 |
| GP-ECON-001 | 钱包和交易 | 获得、花费、余额不足、非法数量、交易记录。 | `test_wallet.gd` | GUT 断言余额、结果对象和 transaction log。 | 无。 |
| GP-PLACE-001 | 放塔经济 | 金币足够放塔并扣费；金币不足、路径格、占用格不扣费不注册塔。 | `test_tower_placement_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | 核心 GUT 覆盖服务；场景 GUT 覆盖点击到放置；gameplay smoke 覆盖 `place_single_tower` checkpoint。 | 多塔成本数据化后的 schema 和回归。 |
| GP-TOWER-001 | 塔类型和数值 | Single、Area、Slow 的 stats、描述、费用和投射物效果。 | `test_tower_config.gd`、`test_tower_attack_service.gd`、`test_projectile_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | GUT 断言 config、攻击结果、状态事件和场景放置类型；gameplay smoke 覆盖 Single/Area/Slow 代表视觉 checkpoint。 | 数据化后需要逐塔 fixture 和 schema 校验。 |
| GP-GROWTH-001 | 塔成长/合成 | 同类型同等级合成成功；类型不匹配、等级不匹配、同一座塔失败。 | `test_tower_merge_service.gd` | 核心 GUT 断言 `TowerMergeResult`。 | 玩家可触达的合成或升级流程尚未定案。 |
| GP-TARGET-001 | 目标选择 | 选择范围内最靠前敌人；无目标、已完成、已击败、射程外忽略。 | `test_targeting_service.gd` | GUT 断言选择出的 enemy 或 null。 | 后续新增 closest/strongest 等策略时扩展矩阵。 |
| GP-COMBAT-001 | 固定 tick 战斗 | 固定 tick 推进移动、攻击、投射物、伤害、奖励、漏怪和胜负状态。 | `test_combat_simulation.gd`、`check-gameplay-smoke.sh` | GUT 断言 tick result、敌人状态、投射物和 game state；gameplay smoke 输出 trace summary、checkpoint 截图和 overlay。 | 长局端到端 run 仍未覆盖。 |
| GP-PROJECTILE-001 | 投射物命中和状态 | 飞行中不命中；命中造成伤害；Area 溅射；Slow 施加减速；非活跃目标忽略。 | `test_projectile_service.gd`、`check-gameplay-smoke.sh` | GUT 断言 damage/status event；gameplay smoke 覆盖 projectile visible、splash impact 和 slow impact checkpoint。 | 多目标拥挤场景和平衡回归。 |
| GP-ENEMY-001 | 敌人生命、死亡和漏怪 | 伤害扣血、致死、重复伤害不重复死亡、未知敌人忽略；完成敌人产生漏怪事件且不重复。 | `test_enemy_damage_service.gd`、`test_enemy_leak_service.gd` | GUT 断言 death/leak event。 | 多敌人类型数据化后的类型 fixture。 |
| GP-REWARD-001 | 击杀和清波奖励 | 击杀奖励入账；清波奖励入账；0 奖励跳过；非对应事件忽略。 | `test_kill_reward_service.gd`、`test_wave_reward_service.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | GUT 断言钱包交易和 HUD 状态；gameplay smoke 覆盖 kill reward 和 wave clear reward 视觉反馈。 | 奖励曲线和平衡目标未定义。 |
| GP-LIFE-001 | 玩家生命和失败 | 漏怪扣生命；生命不低于 0；生命归零进入失败。 | `test_player_life.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | GUT 断言 lives、failure state 和 overlay 集成；gameplay smoke 覆盖 leak 和 defeat checkpoint。 | 无。 |
| GP-WAVE-001 | 波次和胜利 | 按间隔生成；大 delta 不跳过；波次清空；进入下一波；全部波次清空胜利。 | `test_wave_spawner.gd`、`test_combat_simulation.gd`、`test_main_scene.gd`、`check-gameplay-smoke.sh` | GUT 断言 spawn result、wave clear event、victory state；gameplay smoke 覆盖清波胜利 checkpoint。 | MVP 长波次内容和波次数据 schema。 |
| GP-MAP-001 | 关卡和地图数据 | 默认关卡路径、地图 style 和 road guide 数据可加载，非法数据被 schema 拦截。 | `test_map_definitions.gd`、`check-assets.sh` | GUT 和 `check-all.sh` 的资产检查。 | 塔、敌人、波次迁移到数据文件后扩展 schema。 |
| GP-SCENE-001 | 场景可玩路径 | Start 进入 Main；暂停/恢复/重开/返回；放塔；波次推进；奖励、漏怪、胜利、失败 HUD 同步。 | `test_main_scene.gd`、`check-ui-smoke.sh`、`check-gameplay-smoke.sh` | 场景 GUT、native smoke `report.json`、截图、scenario trace 和 overlay。 | Native smoke 目前只覆盖一座塔放置；gameplay smoke 覆盖代表场景但不覆盖完整长局。 |
| GP-DETERMINISM-001 | 确定性回归 | 相同输入序列在固定 tick 下产生相同核心摘要。 | `check-gameplay-smoke.sh`，部分由核心 GUT 间接覆盖 | Gameplay smoke `report.json` 记录 elapsed、tick result、金币、生命、漏怪、胜负、击杀、波次和状态事件摘要。 | 还缺批准式 snapshot 对比和长局 replay。 |

## 更新规则

- 修改 `game/scripts/core/` 玩法规则时，先定位或新增对应 GP 条目，再补 GUT。
- 修改 `BoardView` 的玩家输入路径、HUD 与核心状态同步、暂停、胜利或失败流程时，检查 `GP-SCENE-001` 和 `docs/ui/test-plan.md`。
- 新增玩法功能时，先更新 `docs/gameplay/features.md`，再在本文件添加测试 ID。
- 如果某个行为暂时无法自动化，把缺口写进对应行的“仍缺什么”，不要只写在对话里。

## 常用验证命令

核心规则迭代：

```bash
cd game
./tools/test-gut.sh
```

实质性改动：

```bash
cd game
./tools/check-all.sh
```

影响场景、输入、HUD 或可玩路径：

```bash
cd game
./tools/check-ui-smoke.sh
./tools/check-gameplay-smoke.sh
```
