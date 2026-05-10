# 设计：BoardView 职责拆分

## 状态

Implemented

## 背景

`game/scripts/board/board_view.gd` 曾同时承担一局游戏的应用层状态、资源加载、输入、HUD、响应式布局、渲染、视觉动画和场景流程。这个结构会让后续塔成长、数据化配置、UI 调整和渲染改动互相牵连，也让 agent 很难判断应该改哪一层。

## 目标

- 让玩法应用状态不依赖 Godot 场景节点。
- 让 `BoardView` 最终只做场景生命周期和 adapter 组合。
- 让 GUT、UI smoke 和 gameplay smoke 通过显式 adapter API 访问状态，不再依赖 `BoardView` 镜像字段。
- 让 structural lint 可以逐步从 warning 收紧为 error。

## 非目标

- 不在本设计里重写核心战斗、经济、波次或塔规则。
- 不立即改变玩家可见 UI 和玩法数值。
- 不把塔、敌人、波次和经济配置数据化；这是后续独立工作。

## 方案

最终边界：

| 模块 | 职责 |
| --- | --- |
| `BoardGameSession` | 一局游戏的应用层状态：棋盘、钱包、放置服务、战斗模拟、波次、奖励、胜负 flow 和玩家可见状态文案。 |
| `BoardAssetCatalog` | 关卡、map style、HUD 图标、塔/敌人 sprite 和 FX 资源加载。 |
| `BoardLayoutService` | 根据 viewport 和 board size 计算 board、HUD、tower deck 和 overlay rect。 |
| `BoardHudController` | 绑定 HUD/按钮/overlay 节点，展示 session 状态和处理按钮显示状态。 |
| `BoardInputAdapter` | 将 Godot input 转成选择塔、放置、暂停/恢复等命令。 |
| `BoardVisualState` | 攻击动画、敌人死亡动画、impact feedback 等表现层时间状态。 |
| `BoardRenderer` | 消费 session、layout、visual state 和 assets，绘制棋盘、塔、敌人、投射物和反馈。 |

当前已实现全部模块边界：

- `BoardGameSession` 接管棋盘初始化、放置、战斗推进、奖励、漏怪和胜负状态。
- `BoardLayoutService` 输出纯数据 `BoardLayoutMetrics`，覆盖 board、HUD、tower deck 和 overlay rect。
- `BoardHudController` 负责 HUD 节点绑定、按钮状态、compact 文案和 overlay 展示。
- `BoardInputAdapter` 将 Godot input 转为暂停/恢复、hover 和放置命令。
- `BoardVisualState` 管理攻击动画、敌人死亡动画和 impact feedback 生命周期。
- `BoardRenderer` 消费 board/session/visual/assets 状态进行绘制。
- `BoardMapRenderer` 已从 `game/scripts/core/` 迁到 `game/scripts/board/`。

`BoardView` 现在是组合这些 adapter 的场景生命周期层。它不再镜像 `BoardGameSession`、`BoardLayoutMetrics`、`BoardAssetCatalog` 或 `BoardVisualState` 的字段；场景测试和 smoke runner 通过 `get_session()`、`get_layout_metrics()`、`get_asset_catalog()`、`get_visual_state()` 和 `get_renderer()` 显式访问对应边界。

## 替代方案

- 直接大规模拆成多个 controller：短期代码行数下降更明显，但容易同时破坏场景测试、smoke runner 和 UI 布局。
- 只按文件长度切函数：能降低单文件行数，但不会改善玩法、UI 和渲染的依赖方向。

## 风险

- `BoardView` 仍负责 Godot 生命周期、adapter 组合和部分坐标桥接，后续 UI 功能可能再次把职责塞回同一文件。
- `BoardGameSession` 仍构造默认经济和波次配置，配置数据化还需要单独完成。

## 开放问题

- 塔成长模型确定后，session 是否需要支持更明确的 command/result API。
- 配置数据化时，经济、塔、敌人和波次配置应统一为 JSON、Godot Resource，还是混合方案。
