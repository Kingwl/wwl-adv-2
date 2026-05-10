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
| `core-gameplay-architecture.md` | Implemented | `game/scripts/core/`, `game/scripts/board/board_game_session.gd`, `docs/gameplay/` | 当前核心玩法边界、测试入口和未决配置数据化工作。 |
| `scene-ui-architecture.md` | Implemented | `game/scripts/board/`, `game/scenes/`, `docs/ui/` | 当前场景、UI、BoardView adapter 边界和验证入口。 |
| `map-and-asset-pipeline.md` | Accepted | `game/data/levels/`, `game/data/map_styles/`, assets, `BoardAssetCatalog`, `BoardMapRenderer` | 当前地图/资产流水线和仍未实现的多关卡、数据引用校验。 |
| `test-and-harness-architecture.md` | Implemented | `game/tools/`, `.github/workflows/`, `ci-artifacts/` | 当前测试层级、agent preflight、CI artifacts 和日志报告。 |
| `2026-05-09-road-ribbon-rendering-and-asset-contract.md` | Accepted | `game/tools/generate-road-guide.py`, map assets | 契约已部分验证；确定性道路材质生成仍是未来工作。 |
| `2026-05-09-merge-ui-integration.md` | Deferred | Core merge only: `game/scripts/core/towers/tower_merge_service.gd` | 被“合成还是直接升级”决策阻塞。 |

## 归档索引

`archive/` 保存已实现或已被聚合文档吸收的历史细分设计。需要追溯早期实现取舍时再阅读。

## 工具索引

| 工具 | 状态 | 实现 | 备注 |
| --- | --- | --- | --- |
| 关卡和 map style schema 检查 | Implemented | `game/data/schemas/`, `game/tools/check-assets.sh` | 在 `check-all.sh` 中运行。 |
| Native UI smoke | Implemented | `game/tools/check-ui-smoke.sh`, `game/tools/ui_smoke_runner.gd`, `.github/workflows/ci.yml` | 运行桌面/移动横屏/方形可玩性 smoke，并上传截图。 |
| Agent preflight | Implemented | `game/tools/agent-preflight-fast.sh`, `game/tools/agent-preflight-full.sh`, `game/tools/summarize-godot-log.py`, `game/tools/summarize-ui-smoke.py` | 本地 fast 反馈环不跑视觉 smoke；full 入口保留 UI/gameplay smoke 和截图证据。 |
| Godot Web 导出、Web smoke 和 Pages 可玩构建 | Implemented | `game/export_presets.cfg`, `game/tools/export-web.sh`, `game/tools/check-web-smoke.sh`, `.github/workflows/pages.yml` | 导出产物位于 `game/` 外；Pages 发布到 `/play/` 前运行 headless browser smoke。 |

## 期望

每份新的顶层设计文档都应说明问题、目标、约束、方案、替代方案、风险和开放问题。纯实现步骤、短期清单、功能覆盖矩阵和当前状态优先放到 `docs/status.md`、`docs/gameplay/`、`docs/ui/`、`docs/testing/` 或 `docs/todo/`。

当实现改变设计状态时，更新这个索引；如果当前项目状态也变化，同时更新 `docs/status.md`。历史设计归档时，不要求把归档文件逐条列入顶层索引。
