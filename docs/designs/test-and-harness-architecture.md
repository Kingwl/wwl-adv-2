# 设计：测试和 Harness 架构

## 状态

Implemented

## 背景

项目的 harness 已经覆盖本地门禁、CI、结构 lint、native UI smoke、gameplay smoke、GitHub Pages 导出、Web export smoke 和 agent preflight。早期测试策略和 UI 可玩性验证设计已归档；当前需要一个面向 agent 的入口文档。

## 测试层级

| 层级 | 命令 | 目标 |
| --- | --- | --- |
| 文档检查 | `./tools/check-docs.sh` | 文档地图、必需文件和设计索引不漂移。 |
| 资产检查 | `./tools/check-assets.sh` | 关卡、map style 和塔配置 JSON/schema 有效。 |
| Structural lint | `./tools/check-structure.sh` | core/scene/render 边界和 BoardView 结构约束。 |
| Godot headless | `./tools/godot-headless.sh` | 项目可被 Godot headless 加载。 |
| GUT | `./tools/test-gut.sh` | 核心规则和场景集成测试。 |
| Native UI smoke | `./tools/check-ui-smoke.sh` | start-to-main、响应式视口、基础放置和 UI review artifact。 |
| Native gameplay smoke | `./tools/check-gameplay-smoke.sh` | 代表性玩法 scenario、trace、截图、board crop 和 overlay。 |
| Web export | `./tools/export-web.sh ../build/web` | Godot Web 导出到项目外目录。 |
| Web export smoke | `./tools/check-web-smoke.sh ../build/web-smoke` | 通过本地 HTTP 服务和 headless browser 验证导出页面 canvas 非空且无关键浏览器错误。 |

`./tools/check-all.sh` 聚合文档、资产、结构、环境、headless 和 GUT。CI 在此基础上再运行 native UI smoke 和 native gameplay smoke。Pages workflow 在发布 artifact 前运行 Web export smoke。

## Agent Preflight

- `./tools/agent-preflight.sh` / `./tools/agent-preflight-fast.sh`：本地快速反馈，只运行 `check-all.sh`、生成 Godot/GUT 结构化报告并打印摘要，不运行 native smoke。
- `./tools/agent-preflight-full.sh`：完整交付前反馈，额外运行 native UI smoke 和 native gameplay smoke。

fast 入口用于日常 agent 迭代，避免 native smoke 的 Godot 窗口打断用户操作。需要截图或可玩性证据时显式运行 full 入口。

## 报告和产物

- `ci-artifacts/check-all.log`：完整项目门禁日志。
- `ci-artifacts/godot-log/report.json` / `report.md`：Godot/GUT 结构化日志报告，包含错误、警告、GUT 总数和 TD-007 等已知 warning。
- `ci-artifacts/structure/report.json` / `report.md`：Tree-sitter structural lint 报告。
- `ci-artifacts/ui-smoke/native/`：UI smoke 截图、crop、overlay、Godot log 和报告。
- `ci-artifacts/gameplay-smoke/native/`：gameplay scenario trace、截图、board crop、overlay 和报告。
- `ci-artifacts/web-smoke/`：Web export smoke 的 full-page/canvas 截图、console 事件、`report.json` 和 `report.md`。本地 Playwright venv 位于 `build/web-smoke-python/`，不进入 Godot 项目目录。

CI 上传整个 `ci-artifacts/` 目录，便于 agent 读取失败证据。

## 仍未解决

- GUT 场景测试仍输出 TD-007 ObjectDB leak warning。
- 还没有长局 replay snapshot 或视觉 baseline 对比。
