# 设计：场景和 UI 架构

## 状态

Implemented

## 背景

主棋盘曾由 `BoardView` 同时承担 session、资源加载、输入、HUD、响应式布局、视觉动画和绘制。当前这些职责已经拆成小型 adapter，日常维护应优先读当前边界，而不是历史拆分步骤。

历史场景/UI 设计已归档到 `docs/designs/archive/`。

## 当前边界

| 模块 | 职责 |
| --- | --- |
| `BoardView` | Godot 场景生命周期、adapter 组合、输入入口、绘制入口和少量场景命令。 |
| `BoardGameSession` | 一局游戏的应用层状态，组合核心玩法服务。 |
| `BoardAssetCatalog` | 关卡、map style、HUD 图标、塔/敌人 sprite 和 FX 资源加载。 |
| `BoardLayoutService` / `BoardLayoutMetrics` | 纯数据响应式布局计算。 |
| `BoardHudController` | HUD、塔卡、按钮、状态文本和 overlay 同步。 |
| `BoardInputAdapter` | 把 Godot 输入转换成暂停、恢复、hover 和放置命令。 |
| `BoardVisualState` | 攻击动画、死亡动画和 impact feedback 生命周期。 |
| `BoardRenderer` | 消费 session、layout、assets 和 visual state 绘制棋盘、塔、敌人、投射物和反馈。 |
| `BoardMapRenderer` | 地图背景和可选 cell overlay 的渲染 adapter。 |

`BoardView` 不再保留 session、layout、asset 或 visual state 的兼容镜像字段。场景测试和 smoke runner 使用 `get_session()`、`get_layout_metrics()`、`get_asset_catalog()`、`get_visual_state()` 和 `get_renderer()` 访问对应边界。

## UI 功能来源

- 当前玩家可见 UI surface：`docs/ui/features.md`。
- UI 测试计划和 review artifact：`docs/ui/test-plan.md`。
- 场景/UI 验证门禁：`docs/testing/gates.md`。

新增 UI surface、状态、交互、响应式行为或 smoke review artifact 时，优先更新 `docs/ui/`，只有跨模块架构决策才新增设计文档。

## 验证入口

- 场景 GUT：`game/test/gut/scenes/test_main_scene.gd`。
- Native UI smoke：`cd game && ./tools/check-ui-smoke.sh`。
- 完整交付前：`cd game && ./tools/agent-preflight-full.sh`。
- 结构边界：`cd game && ./tools/check-structure.sh`。

截图、smoke、试玩或审查中看到的每个 UI 问题都记录到 `docs/todo/backlog.md`，不要只写在对话里。

## 仍未解决

- `BoardRenderer` 和 `BoardHudController` 后续仍可继续拆小，但已经不阻塞当前 MVP。
- 本地 native smoke 仍会弹 Godot 窗口；默认 fast preflight 不运行 native smoke，完整视觉证据使用 full preflight 或 CI。
- Web export smoke 已实现为发布信心门禁；当前仍没有像素级视觉 baseline，视觉回归主要依赖 smoke crop、overlay 和人工审查。
