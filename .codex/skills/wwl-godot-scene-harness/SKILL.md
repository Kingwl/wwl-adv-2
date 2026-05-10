---
name: wwl-godot-scene-harness
description: 当在 WWL Advanced 2D Tower Merge Godot 仓库中开发、修改或验证场景、UI、布局、BoardView 行为、输入路由、渲染截图或 native 可玩性 smoke 测试时使用。
metadata:
  short-description: WWL Godot 场景和 UI 验证工作流
---

# WWL Godot 场景 Harness

在 `/Users/bytedance/opensource/wwl-adv-2` 中处理场景/UI 工作时使用这个 skill。

## 优先阅读

1. 阅读 `AGENTS.md`。
2. 阅读 `docs/status.md`。
3. 阅读 `docs/testing/gates.md`。
4. 做 UI surface、状态或交互改动时，阅读 `docs/ui/features.md` 和 `docs/ui/test-plan.md`。
5. 做场景验证工作时，阅读 `docs/designs/scene-ui-architecture.md` 和 `docs/designs/test-and-harness-architecture.md`。
6. 如果用户指定了场景或功能，用 `rg --files game/scenes game/scripts game/test/gut` 找匹配文件。

## 场景开发规则

- 把场景脚本视为渲染、输入、信号、资源加载和状态同步的适配层。
- 玩法规则放在 `game/scripts/core/`；不要把重规则逻辑继续塞进 `BoardView`。
- 棋盘场景资产和 data resource 加载归 `BoardAssetCatalog` 或小型 adapter；不要把新的 `res://` 资产路径和直接 `load()` 调用塞回 `BoardView`。
- 修改场景契约时，更新或新增 `game/test/gut/scenes/` 下的 GUT 场景测试。
- 新增或大改 UI 功能前，先按 `docs/testing/gates.md` 写验证方案：覆盖区域、视口、状态、交互、已有 crop/overlay 覆盖情况，以及需要人工检查的产物。
- 新增 UI surface 时，同步补 `game/tools/ui_smoke_runner.gd` 的局部 crop/overlay；关键状态至少覆盖一个代表状态。
- UI 改动后，检查 `docs/ui/features.md` 和 `docs/ui/test-plan.md` 是否需要更新；新增、删除或改变玩家可见 surface、状态、交互、响应式行为、测试覆盖或 smoke review artifact 时必须同步更新。
- 修改 UI 布局时，在桌面、移动横屏和方形/紧凑视口验证，并检查局部 crop、overlay 辅助线图和 `report.md` 人工检查清单。
- 在截图、smoke、试玩或审查中看到任何 UI 问题或 UI 美观度问题时，把每个问题作为独立 checkbox 记录到 `docs/todo/backlog.md`，不要只放在最终回复里。
- 本地 Web 导出产物必须放在 `game/` 外。

## 场景验证

native UI/可玩性 smoke：

```bash
cd game
./tools/check-ui-smoke.sh
```

native gameplay smoke：

```bash
cd game
./tools/check-gameplay-smoke.sh
```

只调试单个视口时：

```bash
cd game
UI_SMOKE_VIEWPORTS=1280x720 ./tools/check-ui-smoke.sh
```

重新打印最近一次报告：

```bash
cd game
./tools/summarize-ui-smoke.py
```

本地快速 preflight：

```bash
cd game
./tools/agent-preflight.sh
```

完整视觉/可玩性 preflight：

```bash
cd game
./tools/agent-preflight-full.sh
```

修改 BoardView 结构、资源加载或场景/核心边界时：

```bash
cd game
./tools/check-structure.sh
```

## 覆盖边界

当前 native smoke runner 覆盖开始到主场景的可玩路径：

- `res://scenes/start.tscn`
- `res://scenes/main.tscn`
- 通过场景输入路径放置一座塔
- 桌面、移动横屏和方形视口的截图检查

如果用户要求测试其他场景，不要暗示当前 smoke runner 已覆盖它。应新增 GUT 场景测试、为 `game/tools/ui_smoke_runner.gd` 扩展明确的场景契约，或清楚说明只做了手工/本地验证。

## 失败定位

判断失败原因前先检查这些产物：

- `ci-artifacts/ui-smoke/native/report.json`
- `ci-artifacts/ui-smoke/native/report.md`
- `ci-artifacts/gameplay-smoke/native/report.json`
- `ci-artifacts/gameplay-smoke/native/report.md`
- `ci-artifacts/ui-smoke/native/godot.log`
- `ci-artifacts/ui-smoke/native/*.png`
- `ci-artifacts/gameplay-smoke/native/scenarios/**/*.png`

关键 UI 审查优先看这些局部产物：

- `*-hud-resources.png` 和 `*-hud-resources-overlay.png`
- `*-status-*.png` 和 `*-status-*-overlay.png`
- `*-tower-deck*.png` 和 `*-tower-deck*-overlay.png`
- `*-start-screen.png` 和 `*-start-screen-overlay.png`
- `*-pause-overlay.png`、`*-victory-overlay.png`、`*-defeat-overlay.png` 及对应 overlay

把失败归类为：场景加载、节点缺失、布局越界、输入路由、玩法状态、空白渲染或 Godot 运行时错误。只修复拥有该问题的最小层。
