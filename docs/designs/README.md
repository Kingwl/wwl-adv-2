# 设计

这个目录用于当前仍有维护价值的设计提案、架构说明和决策记录。

已经实现并被当前功能清单、测试计划或聚合架构文档吸收的历史设计，放在 `archive/`。日常 agent 工作不要从归档设计开始阅读。

## 状态值

- `Draft`：已提出但尚未接受。
- `Accepted`：方向已选定，但尚未完全实现。
- `Implemented`：已体现在代码和测试中。
- `Deferred`：仍有参考价值，但有意暂停。
- `Superseded`：已被其他设计替代。

## 设计索引

| 设计 | 状态 | 实现 | 备注 |
| --- | --- | --- | --- |
| `core-gameplay-architecture.md` | Implemented | `game/scripts/core/`, `game/scripts/board/board_game_session.gd`, `docs/gameplay/` | 当前核心玩法边界、测试入口和数据化配置入口。 |
| `scene-ui-architecture.md` | Implemented | `game/scripts/board/`, `game/scenes/`, `docs/ui/` | 当前场景、UI、BoardView adapter 边界和验证入口。 |
| `map-and-asset-pipeline.md` | Accepted | `game/data/`, assets, `BoardAssetCatalog`, `BoardMapRenderer` | 当前地图/资产流水线；5 个 MVP level 和 map style、经济、敌人、波次、塔和塔视觉资源引用已进入 asset check。 |
| `2026-05-11-mvp-level-wave-cadence.md` | Accepted | `game/data/levels/`, `game/data/waves/`, `LevelDefinition`, `WaveConfig`, `check-assets.sh`; pending balance smoke | MVP 五关 8 波节奏、奖励曲线、level-specific wave set 数据契约和第一版差异化地图。 |
| `test-and-harness-architecture.md` | Implemented | `game/tools/`, `.github/workflows/`, `ci-artifacts/` | 当前测试层级、agent preflight、CI artifacts 和日志报告。 |
| `2026-05-10-attack-defense-damage-system.md` | Implemented | `DamageTypes`, `DamageAffinityConfig`, `Enemy`, `EnemyCatalog`, `WaveConfig`, `DamageEvent`, `EnemyDamageService`, `TowerConfig`, `game/data/` | 参考 Warcraft III 的攻击/护甲克制，并加入伤害类型和种族抗性：武器形态推导攻击类型，防御类型处理武器克制，种族处理冰火毒电抗性。塔、敌人和波次数据文件第一版已实现；UI 展示仍待后续。 |
| `2026-05-10-initial-tower-roster.md` | Accepted | `TowerConfig`, `BoardHudController`, `BoardAssetCatalog` | 初期塔类型和实现批次：弩塔、炮塔、冰霜塔、火焰塔、毒针塔、雷霆塔；当前已实现 Single/Area/Slow/Flame/Poison 五塔，雷霆塔仍待后续。 |
| `2026-05-10-tower-mechanics-effects-system.md` | Accepted | `TowerEffect`, `StatusEffect`, `StatusEffectService`, `CombatSimulation`, `PathFollower`, `TowerConfig`, `ProjectileService` | 塔机制扩展框架：攻击模式、效果列表、通用状态、DoT、视觉事件，以及短期和长期塔机制边界。第一版已实现通用状态运行时、减速移动倍率、DoT 伤害事件、`effects[]`、Flame 灼烧塔和 Poison 毒针塔；独立视觉事件、雷霆塔仍待实现。 |
| `2026-05-10-tower-upgrade-system.md` | Implemented | `game/data/towers/towers.json`, `TowerConfig`, `TowerPlacementService`, `BoardHudController`, `test_tower_config.gd`, `test_tower_placement_service.gd`, `test_main_scene.gd` | 塔升级机制第一版：普通升级只做数值提升，每次升级都提升伤害和攻击范围，升级不清空冷却，菜单显示升级预览；建造费用、tier 数值和 effects 已迁移到塔数据文件。 |
| `2026-05-10-tower-action-menu-upgrades.md` | Implemented | `TowerConfig`, `TowerPlacementService`, `BoardView`, `BoardHudController`, `ui_smoke_runner.gd` | Prototype 塔成长模型：点击塔弹出 Upgrade/Remove 菜单，直接升级和 50% 拆除返还。 |
| `2026-05-09-road-ribbon-rendering-and-asset-contract.md` | Accepted | `game/tools/generate-road-guide.py`, map assets | 契约已部分验证；确定性道路材质生成仍是未来工作。 |
| `2026-05-09-merge-ui-integration.md` | Superseded | Core merge only: `game/scripts/core/towers/tower_merge_service.gd` | Prototype 已选择直接升级菜单；此文档仅保留为未来随机召唤/合成经济参考。 |

## 归档索引

`archive/` 保存已实现或已被聚合文档吸收的历史细分设计。需要追溯早期实现取舍时再阅读。

## 工具索引

| 工具 | 状态 | 实现 | 备注 |
| --- | --- | --- | --- |
| 关卡、map style、经济、敌人、波次和塔 schema 检查 | Implemented | `game/data/schemas/`, `game/tools/check-assets.sh` | 在 `check-all.sh` 中运行，并校验 wave enemy reference 与 tower visual resource reference。 |
| 地图 layout guide 生成 | Implemented | `game/tools/generate-map-layout-guide.py` | 从 `game/data/levels/*.json` 生成图像模型参考图、background reference、grid-layer reference、语义 mask、contract 和技术 prompt fragment，固定分层地图的外圈景观、中间空地、内部可建造区和路径。 |
| 地图 deterministic grid layer 合成 | Accepted | `game/tools/compose-map-grid-layer.py`, `long_road_v1` / `kill_zone_v1` / `armored_column_v1` / `mvp_showcase_v1` | 读取关卡 JSON，可先生成 clean playfield 背景，再合成透明道路、成簇塔台和内部 blocker 覆盖层；Level 2-5 已接入。 |
| 地图视觉采样审查 | Implemented | `game/tools/generate-map-visual-review.py` | 对背景、grid layer、composed preview、buildable-grid 和 path-enemies 截图生成固定语义 crop，并用可配置 block size 输出 nearest、BOX、mean 和 median 降采样对比。 |
| Native UI smoke | Implemented | `game/tools/check-ui-smoke.sh`, `game/tools/ui_smoke_runner.gd`, `.github/workflows/ci.yml` | 运行桌面/移动横屏/方形可玩性 smoke，并上传截图、局部 crop、overlay 和 4x4 visual-review contact sheet。 |
| UI 视觉采样审查 | Implemented | `game/tools/generate-ui-visual-review.py` | 从 UI smoke `report.json` 生成整屏 4x4 contact sheet、关键 crop 4x4 contact sheet、逐视口 crop atlas 和 manifest。 |
| Agent preflight | Implemented | `game/tools/agent-preflight-fast.sh`, `game/tools/agent-preflight-full.sh`, `game/tools/summarize-godot-log.py`, `game/tools/summarize-ui-smoke.py` | 本地 fast 反馈环不跑视觉 smoke；full 入口保留 UI/gameplay smoke 和截图证据。 |
| Godot Web 导出、Web smoke 和 Pages 可玩构建 | Implemented | `game/export_presets.cfg`, `game/tools/export-web.sh`, `game/tools/check-web-smoke.sh`, `.github/workflows/pages.yml` | 导出产物位于 `game/` 外；Pages 发布到 `/play/` 前运行 headless browser smoke。 |

## 期望

每份新的顶层设计文档都应说明问题、目标、约束、方案、替代方案、风险和开放问题。纯实现步骤、短期清单、功能覆盖矩阵和当前状态优先放到 `docs/status.md`、`docs/gameplay/`、`docs/ui/`、`docs/testing/` 或 `docs/todo/`。

当实现改变设计状态时，更新这个索引；如果当前项目状态也变化，同时更新 `docs/status.md`。历史设计归档时，不要求把归档文件逐条列入顶层索引。
