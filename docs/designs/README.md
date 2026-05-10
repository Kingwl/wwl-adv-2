# 设计

这个目录用于设计提案、架构说明和决策记录。

## 状态值

- `Draft`：已提出但尚未接受。
- `Accepted`：方向已选定，但尚未完全实现。
- `Implemented`：已体现在代码和测试中。
- `Deferred`：仍有参考价值，但有意暂停。
- `Superseded`：已被其他设计替代。

## 设计索引

| 设计 | 状态 | 实现 | 备注 |
| --- | --- | --- | --- |
| `2026-05-08-godot-2d-tower-defense-merge.md` | Implemented | `game/`, `game/scripts/core/` | 整体产品和架构方向。 |
| `2026-05-08-testing-coverage-strategy.md` | Implemented | `game/test/gut/`, `docs/testing/`, `game/tools/` | GUT 优先策略；尚无行覆盖率门禁。 |
| `2026-05-08-board-grid-rules.md` | Implemented | `game/scripts/core/board/` | 放置、移除、格子类型、路径校验。 |
| `2026-05-08-board-scene-adapter.md` | Implemented | `game/scripts/board/board_view.gd`, `game/scripts/board/board_*` adapters | 场景适配层已拆成 session、layout、HUD、input、visual state 和 renderer adapter。 |
| `2026-05-08-economy-resource-system.md` | Implemented | `game/scripts/core/economy/`, `game/scripts/core/placement/` | 放置费用和奖励已实现。 |
| `2026-05-08-enemy-path-movement.md` | Implemented | `game/scripts/core/movement/`, `game/scripts/core/enemies/` | 确定性路径进度和场景渲染。 |
| `2026-05-08-single-enemy-health-death.md` | Implemented | `game/scripts/core/enemies/`, `game/scripts/core/combat/` | 生命、伤害、死亡事件、奖励。 |
| `2026-05-08-fixed-tick-combat-simulation.md` | Implemented | `game/scripts/core/combat/combat_simulation.gd` | 固定 tick 战斗循环已启用。 |
| `2026-05-08-projectile-hit-detection.md` | Implemented | `game/scripts/core/combat/projectile_service.gd` | 真实投射物移动和命中事件。 |
| `2026-05-08-tower-types-framework.md` | Implemented | `game/scripts/core/towers/` | Single、Area、Slow 塔类型；属性仍有硬编码。 |
| `2026-05-08-wave-system.md` | Implemented | `game/scripts/core/waves/` | 当前 3 波；MVP 需要更多内容和数据文件。 |
| `2026-05-08-victory-failure-conditions.md` | Implemented | `game/scripts/core/player/`, `game/scripts/core/combat/` | 生命、漏怪处理、胜负结果。 |
| `2026-05-08-game-flow-ui.md` | Implemented | `game/scenes/`, `game/scripts/board/board_view.gd` | 开始、暂停、重开、返回、胜利和失败流程。 |
| `2026-05-08-grid-aligned-map-pipeline.md` | Implemented | `game/data/levels/`, `game/data/map_styles/`, assets | 当前地图遵循网格对齐契约。 |
| `2026-05-09-path-guide-road-generation.md` | Implemented | `game/tools/generate-road-guide.py`, `game/tools/out/` | Guide/mask 产物由玩法路径数据生成。 |
| `2026-05-09-road-ribbon-rendering-and-asset-contract.md` | Accepted | `game/tools/generate-road-guide.py`, map assets | 契约已部分验证；确定性道路材质生成仍是未来工作。 |
| `2026-05-09-merge-ui-integration.md` | Deferred | Core merge only: `game/scripts/core/towers/tower_merge_service.gd` | 被“合成还是直接升级”决策阻塞。 |
| `2026-05-09-ui-playability-validation.md` | Accepted | `game/tools/check-ui-smoke.sh`; proposed Web smoke | Native smoke 已用于开发；Web smoke 仍是未来发布门禁。 |
| `2026-05-10-board-view-decomposition.md` | Implemented | `game/scripts/board/board_game_session.gd`, `board_layout_service.gd`, `board_hud_controller.gd`, `board_visual_state.gd`, `board_renderer.gd` | `BoardView` 现在是场景生命周期层，并通过显式 getter 暴露 session、layout、assets、visual state 和 renderer 边界。 |

## 工具索引

| 工具 | 状态 | 实现 | 备注 |
| --- | --- | --- | --- |
| 关卡和 map style schema 检查 | Implemented | `game/data/schemas/`, `game/tools/check-assets.sh` | 在 `check-all.sh` 中运行。 |
| Native UI smoke | Implemented | `game/tools/check-ui-smoke.sh`, `game/tools/ui_smoke_runner.gd`, `.github/workflows/ci.yml` | 运行桌面/移动横屏/方形可玩性 smoke，并上传截图。 |
| Agent preflight | Implemented | `game/tools/agent-preflight.sh`, `game/tools/summarize-ui-smoke.py` | 本地 agent 反馈环：项目门禁加 UI smoke 摘要。 |
| Godot Web 导出和 Pages 可玩构建 | Implemented | `game/export_presets.cfg`, `game/tools/export-web.sh`, `.github/workflows/pages.yml` | 导出产物位于 `game/` 外；Pages 发布到 `/play/`。 |

## 期望

每份设计文档都应说明问题、目标、约束、方案、替代方案、风险和开放问题。

当实现改变设计状态时，更新这个索引；如果当前项目状态也变化，同时更新 `docs/status.md`。
