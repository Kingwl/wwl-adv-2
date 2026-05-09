# 设计：BoardView 职责拆分

## 状态

Accepted

## 背景

`game/scripts/board/board_view.gd` 曾同时承担一局游戏的应用层状态、资源加载、输入、HUD、响应式布局、渲染、视觉动画和场景流程。这个结构会让后续塔成长、数据化配置、UI 调整和渲染改动互相牵连，也让 agent 很难判断应该改哪一层。

## 目标

- 让玩法应用状态不依赖 Godot 场景节点。
- 让 `BoardView` 最终只做场景生命周期和 adapter 组合。
- 保持现有 GUT、UI smoke 和 gameplay smoke 可以逐步迁移，不做一次性高风险重写。
- 让 structural lint 可以逐步从 warning 收紧为 error。

## 非目标

- 不在本设计里重写核心战斗、经济、波次或塔规则。
- 不立即改变玩家可见 UI 和玩法数值。
- 不立即移除所有 `BoardView` 兼容字段；smoke runner 和场景测试会分阶段迁移。

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

当前已实现第一步：`BoardGameSession` 接管棋盘初始化、放置、战斗推进、奖励、漏怪和胜负状态。`BoardView` 保留兼容字段作为 facade，确保现有场景测试和 smoke runner 不需要一次性改写。

推荐后续顺序：

1. 迁移场景测试和 smoke runner，减少直接写 `board_view.*` 状态。
2. 拆 `BoardLayoutService`，先把响应式几何计算变成纯逻辑测试。
3. 拆 `BoardHudController`，把 HUD 节点绑定、按钮状态和 overlay 展示迁出。
4. 拆 `BoardVisualState`，让视觉反馈状态和 session 分离。
5. 拆 `BoardRenderer`，最后迁出 `_draw_*`。
6. 将 `BoardMapRenderer` 从 `game/scripts/core/` 迁到场景/渲染 adapter。

## 替代方案

- 直接大规模拆成多个 controller：短期代码行数下降更明显，但容易同时破坏场景测试、smoke runner 和 UI 布局。
- 只按文件长度切函数：能降低单文件行数，但不会改善玩法、UI 和渲染的依赖方向。

## 风险

- facade 阶段存在双向同步成本；外部测试仍可直接改 `board_view` 兼容字段。
- `BoardView` 行数仍然偏大，HUD、layout、渲染和视觉状态还未迁出。
- `BoardGameSession` 仍构造默认经济和波次配置，配置数据化还需要单独完成。

## 开放问题

- 塔成长模型确定后，session 是否需要支持更明确的 command/result API。
- 配置数据化时，经济、塔、敌人和波次配置应统一为 JSON、Godot Resource，还是混合方案。
- `BoardRenderer` 拆出后是否应把 `BoardMapRenderer` 合并为其子模块。
