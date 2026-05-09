# Design: 格子场景接入

## Status

Implemented. BoardView now uses a responsive landscape layout for desktop and mobile-style wide viewports.

## Context

核心 `Board` 规则已经实现并通过 GUT 测试。下一步需要在 Godot 场景中把棋盘可视化，并把玩家点击转换成核心规则调用。

目标是先做一个可观察、可点击、可验证的 Prototype 场景，而不是完整美术。

## Goals

- 在主场景显示 `10x8` 格子地图。
- 显示路径格、可建造格、已占用格的不同状态。
- 鼠标点击可建造格时调用 `Board.place_tower()`。
- 点击路径格、越界格、占用格时能看到明确反馈。
- 场景层保持薄，只做输入、渲染和反馈，不重写核心规则。
- 用 GUT 增加一个主场景加载/基础节点存在的集成测试。
- 棋盘和 HUD 需要适配手机横屏，不依赖单一固定坐标。

## Non-Goals

- 暂不做最终美术。
- 暂不做拖拽合成。
- 暂不做竖屏布局。
- 暂不做安全区刘海/圆角的最终适配。

## Scene Structure

建议主场景结构：

```text
Main (Node2D)
├── BoardView (Node2D)
│   ├── GridLayer (Node2D)
│   ├── TowerLayer (Node2D)
│   └── FeedbackLayer (Node2D)
└── Hud (CanvasLayer)
    ├── Status (Label)
    └── Hint (Label)
```

## Scripts

建议新增：

```text
game/scripts/board/
├── board_view.gd
└── board_scene_config.gd

game/test/gut/scenes/
└── test_main_scene.gd
```

`board_view.gd` 负责：

- 持有一个 `Board` 实例。
- 初始化固定路径。
- 绘制格子。
- 将鼠标坐标转换为 `Vector2i`。
- 点击后调用 `Board.place_tower()`。
- 根据 `PlacementResult` 更新 UI 反馈。

`board_scene_config.gd` 可以后续承载：

- 棋盘宽高。
- 格子尺寸。
- 棋盘原点。
- 路径坐标。
- 颜色配置。

MVP 可以先把配置写在 `board_view.gd`，但不要把核心放置规则写在场景脚本里。

## Visual Rules

先用 `draw_rect` 做占位视觉：

| State | Suggested Color |
| --- | --- |
| Buildable | muted green |
| Path | muted gray-blue |
| Blocked | dark gray |
| Locked | dim purple-gray |
| Occupied | amber/cyan circle or square |
| Hover valid | light outline |
| Invalid click | red flash/outline |

画面应清晰表达：

- 哪里能放塔。
- 敌人路径在哪里。
- 哪些格子已经占用。
- 最近一次点击是否成功。

## Input Rules

点击流程：

1. `_unhandled_input(event)` 捕获左键点击。
2. `local_mouse_position -> grid_position`。
3. 如果越界，展示 `OUT_OF_BOUNDS` 反馈。
4. 调用 `board.place_tower(grid_position, next_tower_id)`。
5. 成功时渲染塔占位，并更新 `Status`。
6. 失败时不改变棋盘，只更新 `Status`。

`next_tower_id` Prototype 可以用递增 id：

```text
tower-1
tower-2
tower-3
```

## Initial Prototype Map

默认：

- `width = 10`
- `height = 8`
- 设计基准 viewport 为 `1280x720`
- 最大 `cell_size = 64`
- `origin` 由当前 viewport 动态计算

路径：

```text
(0,3) -> (1,3) -> (2,3) -> (3,3) -> (4,3)
                                      |
                                      v
                                   (4,4) -> (5,4) -> (6,4) -> (7,4) -> (8,4) -> (9,4)
```

对应数组：

```gdscript
[
	Vector2i(0, 3),
	Vector2i(1, 3),
	Vector2i(2, 3),
	Vector2i(3, 3),
	Vector2i(4, 3),
	Vector2i(4, 4),
	Vector2i(5, 4),
	Vector2i(6, 4),
	Vector2i(7, 4),
	Vector2i(8, 4),
	Vector2i(9, 4),
]
```

## Responsive Landscape Layout

当前项目把 `1280x720` 当作设计基准：

```text
display/window/size/viewport_width = 1280
display/window/size/viewport_height = 720
display/window/stretch/mode = canvas_items
display/window/stretch/aspect = expand
```

BoardView 每次 viewport 变化时重新计算：

- HUD 保留顶部横屏区域，显示 Gold、Lives、Wave、固定塔栏、Status、Hint。
- 固定塔栏使用三张塔卡展示塔名、价格、当前选择和不可购买状态。
- 棋盘占用 HUD 下方剩余区域。
- `cell_size = min(64, floor(available_width / 10, available_height / 8))`。
- 棋盘在可用区域内水平居中，并在 HUD 下方垂直居中。
- 点击坐标通过当前 `board_origin` 和 `cell_size` 转换成格子坐标。

这样桌面窗口、iPhone/Android 常见横屏比例都能保持棋盘完整可见。后续真机导出时，还需要在移动端 export preset 中锁定 landscape orientation，并补安全区适配。

## Scene Tests

先加轻量 GUT 集成测试：

- `main.tscn` 可以加载。
- `BoardView` 节点存在。
- `Hud/Status` 节点存在。
- `BoardView` 初始化后有 `Board` 实例。
- 默认路径校验成功。

后续再加输入测试：

- 模拟点击可建造格，产生 tower occupant。
- 模拟点击路径格，返回 `NOT_BUILDABLE`。
- 模拟重复点击同一格，返回 `OCCUPIED`。
- 模拟手机横屏 viewport，棋盘不超出屏幕。
- 缩放布局后，格子中心仍能映射回正确坐标。

## Roadmap

### Step 1: BoardView Skeleton

- [x] 新增 `BoardView` 节点和脚本。
- [x] 初始化 `Board.new(10, 8)`。
- [x] 设置默认路径。
- [x] 更新 `main.tscn` 节点结构。

完成标准：

- 主场景打开后能看到格子地图和路径。
- `./tools/godot-headless.sh` 通过。

### Step 2: Grid Rendering

- [x] 用 `_draw()` 绘制 10x8 格子。
- [x] 路径格和建造格颜色不同。
- [x] 已占用格显示塔占位形状。
- [x] hover 格显示描边。

完成标准：

- 玩家一眼能区分路径和可建造区。

### Step 3: Click Placement

- [x] 鼠标点击转 `Vector2i`。
- [x] 点击可建造格放置 tower 占位。
- [x] 点击路径格显示失败原因。
- [x] 点击已占用格显示失败原因。
- [x] 状态文字显示最近一次操作结果。

完成标准：

- 可以通过点击放置多个塔。
- 不允许在路径或已占用格放塔。

### Step 4: Scene Tests

- [x] 添加 `test_main_scene.gd`。
- [x] 测试主场景加载。
- [x] 测试 `BoardView` 初始化。
- [x] 测试默认路径合法。
- [x] 测试手机横屏 viewport 下棋盘完整可见。
- [x] 测试响应式缩放后坐标映射仍正确。

完成标准：

- `./tools/test-gut.sh` 包含场景测试且全部通过。

### Step 5: Responsive Landscape Layout

- [x] 启用 canvas item stretch 和 expand aspect。
- [x] BoardView 根据 viewport 动态计算 `cell_size` 和 `board_origin`。
- [x] HUD 根据横屏宽度动态排布。

完成标准：

- `844x390` 这类手机横屏尺寸下，棋盘完整落在 viewport 内。
- 缩放后点击坐标仍能映射到正确格子。

## Open Questions

- BoardView 是否先用纯 `_draw()`，还是直接用 TileMapLayer。建议 Prototype 用 `_draw()`，后续关卡编辑再评估 TileMapLayer。
- 点击放塔的 tower 类型是否先固定为 `SINGLE_TARGET`。建议先固定，等经济和塔选择 UI 再扩展。
