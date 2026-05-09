# 设计：Road Ribbon 渲染和资产契约

## 状态

Draft

## 背景

已移除的语义化 road overlay prototype 使用小型 atlas：直线、四个转弯和十字。`BoardMapRenderer` 根据邻近 path cell 选择 tile，并把每个 tile 绘制进网格格子。这保持了玩法对齐，但仍要求生成图片解决困难几何问题：精确道路宽度、边缘对齐和转弯连续性。Draw padding 只能隐藏部分问题，且视觉效果不如 baked guide 工作流。

当前活跃运行时 style 使用由精确 path guide 生成的整棋盘 baked 背景。未来任何 road-ribbon renderer 都应为可编辑地图替代 baked road path，而不是重新引入语义化 road tiles。

## 行业参考

- Tilemap 仍是标准 2D 游戏表示方式，因为视觉网格可以和 collision、pathfinding 等逻辑数据共享结构；MDN 将 tile atlas、地图尺寸、视觉网格和逻辑网格描述为常见数据模型：<https://developer.mozilla.org/en-US/docs/Games/Techniques/Tilemaps>。
- Godot TileMap terrains 支持自动连接模式（`Connect`、`Path`）和针对未解决情况的显式 tile override。这和 autotiling 是同类方案：拓扑选择美术变体，而不是手工逐格摆放：<https://docs.godotengine.org/en/4.0/tutorials/2d/using_tilemaps.html#handling-tile-connections-automatically-using-terrains>。
- Tiled terrain sets 也明确区分：tiles 通过 corner/edge/mixed terrain layout 标记，编辑器会调整邻居让过渡连接。它的 Patterns view 会暴露缺失 pattern，这是这里做验证时有用的经验：<https://docs.mapeditor.org/en/latest/manual/terrain/>。
- Unity 的 2D Tilemap Extras 包含 Rule Tile 和自定义 brush，是另一种用邻居规则选择 sprite，而不是手工创作每个 placement 的例子：<https://docs.unity.cn/Manual/com.unity.2d.tilemap.extras.html>。
- Unity Sprite Shape 是道路/路径应呈连续曲线时的另一种行业模式：使用 path、角度范围和指定 sprite。对本项目来说，等价物是在 Godot 棋盘上的确定性 path/ribbon renderer：<https://docs.unity.cn/Packages/com.unity.2d.spriteshape%406.0/manual/index.html>。
- Godot 也有适合项目原生 renderer 的底层 2D path 工具：`Line2D` 支持线宽、圆角 join/cap、贴图模式和抗锯齿；`Geometry2D.offset_polyline()` 可将中心线膨胀成圆角多边形：<https://docs.godotengine.org/en/3.3/classes/class_line2d.html> 和 <https://docs.godotengine.org/en/stable/classes/class_geometry2d.html#class-geometry2d-method-offset-polyline>。
- OpenAI 图像 mask 可作为有用指导，但官方图像生成指南指出 mask 遵循是基于 prompt 的，可能无法精确匹配 mask 形状。因此 mask 可帮助生成源贴图，但不能成为最终几何真相来源：<https://platform.openai.com/docs/guides/images/image-generation#edit-an-image-using-a-mask-inpainting>。

## 目标

- 在不改变玩法 path cells 的情况下，让可见路径在拐角处更宽、更平滑。
- 不再依赖图像生成产出精确道路几何。
- 地图渲染保持确定性、可测试，并由 `level_001.json` 的 path cells 驱动。
- 将生成美术限制为可被代码裁剪、平铺或采样的 texture/material 输入。
- 为未来道路资产提供机器可检查的验收标准。

## 非目标

- 立即将整个棋盘切换到 Godot `TileMap`。
- 替换敌人移动；敌人继续沿 `path_cells` 定义的中心线移动。
- 让图像模型生成完美完整道路 atlas 作为主要路径。

## 方案

用 `road_ribbon` renderer 替代 road overlay atlas 路径：

1. 使用每个格子的中心点，将 `path_cells` 转换为 board-local 坐标中的中心线。
2. 通过将每个拐角替换为四分之一圆弧来平滑 90 度转弯。圆弧半径由 style 定义，并被 clamp，确保不会离开相邻 path cells。
3. 围绕中心线将道路主体渲染为确定性 ribbon：
   - `body_width_cells`：默认 `0.78`。
   - `curb_width_cells`：默认 `0.10`。
   - `edge_feather_cells`：默认 `0.03`。
   - `turn_radius_cells`：默认 `0.36`。
   - joins：round。
   - endpoints：square 或 round，由 style 定义。
4. 按顺序绘制层：
   - background frame。
   - road shadow/ambient edge。
   - curb 或 border ribbon。
   - 使用 seamless pavement material 填充的 paved road body。
   - 可选 edge decoration sprites，沿 ribbon edge 采样，并由 seed 确定。
5. 不保留语义化 tile renderer 作为替代运行时路径。

如果引入 road ribbon 渲染，style 数据应使用结构化 road block：

```json
{
  "road": {
    "render_mode": "ribbon",
    "body_width_cells": 0.78,
    "curb_width_cells": 0.10,
    "edge_feather_cells": 0.03,
    "turn_radius_cells": 0.36,
    "end_cap": "square",
    "join": "round",
    "seed": 1001,
    "materials": {
      "pavement": "res://assets/tilesets/stormwind_city_v3/road_pavement_seamless.png",
      "curb": "res://assets/tilesets/stormwind_city_v3/road_curb_seamless.png",
      "edge_decals": "res://assets/tilesets/stormwind_city_v3/road_edge_decals.png"
    }
  }
}
```

## 图像生成契约

图像生成不应再创建道路拓扑。它只应创建这些源资产：

- `road_pavement_seamless.png`：方形 seamless 材质，无透视道路形状、无边界、无 alpha-critical silhouette。
- `road_curb_seamless.png`：renderer 用于 curb 层的方形或条带材质。
- `road_edge_decals.png`：透明装饰 sprites，例如杂草、小花、裂缝和石头，由确定性后处理提取。
- 可选 `style_reference.png`：仅用于保持材质语言的非运行时 mood image。

prompt 应由 JSON 契约生成，不应每次手写。prompt 必须明确说明：

- "Draw material texture only, not a road, not a path, not a turn."
- "Seamless tileable top-down stone paving."
- "No perspective bend, no junction, no border, no text, no watermark."
- "Camera: top-down / slightly 3/4 top-down consistent with the board background."
- "Output is source material; final road width and shape will be clipped by engine geometry."

确定性处理器拥有硬规则：

- 裁剪或 resize 到所需尺寸。
- 需要 alpha 时，从生成 mask 强制 alpha。
- 对相对边缘做 seam similarity 检查。
- 拒绝包含明显道路拓扑而不是材质的资产。
- 输出一个 preview，将生成材质裁剪到真实 `level_001` 路径中。

这样 prompt 失败代价更低：如果图像漂移，我们重新生成材质，而不是整套道路 atlas。renderer 仍保证宽度、拐角半径和连通性。

## 验证

替换运行时 renderer 前，先添加测试/工具：

- 单测从 `path_cells` 提取中心线。
- 单测当前路线的拐角平滑：两个 90 度转弯产生方向单调的圆弧点，并保持在棋盘边界内。
- 单测 ribbon config 解析和 clamp。
- 像素/几何测试：在直线路段和转弯中心采样的 road body 宽度在容差内。
- preview generator：为活跃 level/style 写出 `road_ribbon_preview.png`。
- 生成材质的资产校验器：
  - 尺寸匹配契约。
  - pavement 不透明。
  - edge decal sheet 有 alpha。
  - seamless material edge delta 低于阈值。
  - 没有生成资产需要定义道路 silhouette。

## 替代方案

- 完整 autotile atlas：使用 16/47 neighbor-mask road tiles，校验每条边，并可选择 Godot terrain sets。这是成熟 tilemap 路径，但对本项目的平滑宽道路来说，仍要求模型或美术产出大量精确转弯/路口形状。
- 保留 7-tile 语义化 atlas 并继续调 padding。简单，但 tile alpha 形状不受控，无法保证平滑转弯。
- 生成一张整棋盘 baked road image。一次效果可以很好，但会破坏 grid-aligned 契约，并让未来路径变更变贵。

## 实现计划

1. 添加 `RoadStyleDefinition`，解析结构化 `road` block。
2. 在 `game/scripts/core/maps/` 中添加 `RoadRibbonBuilder`，提供纯几何方法。
3. 为中心线、圆弧、clamp 和 ribbon 尺寸添加 GUT 测试。
4. 添加 `BoardMapRenderer.draw_road_ribbon()`，不保留已移除的 tile mode。
5. 添加 `game/tools/render-road-preview.py` 或 Godot headless helper 来导出 preview。
6. 生成或复用 pavement/curb/decal 源材质，然后用 preview 工具验证。
7. ribbon renderer 发布后，移除所有临时 preview-only road material assets。

## 风险

- Godot `draw_polygon` texture fill 可能需要额外 UV 处理才能良好平铺。如果这变得麻烦，可以在 load time 将 road ribbon bake 成图片，然后绘制单张 texture。
- 过度平滑的转弯可能视觉上离开单格路径 footprint。需要 clamp 半径并添加几何测试。
- Curb decoration 可能变得嘈杂。保持 edge decals 可选，并由 seed 确定。

## 开放问题

- 道路端点应是方形 city-gate cut 还是圆形 cap？
- 道路主体应在 Godot 中通过重复 UV 贴图，还是由工具 bake 成一张 overlay image？
- 是否很快需要路口，还是第一版 renderer 只覆盖简单非分支路径？
