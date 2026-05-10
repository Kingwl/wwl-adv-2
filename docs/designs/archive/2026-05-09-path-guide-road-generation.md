# 设计：Path Guide 道路生成

## 状态

Accepted。

## 背景

原始地图道路使用小型 road-tile overlay atlas。这让玩法和 `path_cells` 保持对齐，但视觉质量依赖生成的转弯 tile 是否足够宽、连接是否干净。实际效果中，拐角太窄，draw padding 也只能隐藏部分问题。

当前 map style 使用更好的工作流：

1. 从玩法数据生成精确道路 guide。
2. 让图像生成基于该 guide 风格化出完整棋盘图。
3. 保持玩法路径数据不变。
4. 将生成结果集成为运行时 baked map style。

这个文档记录该工作流，让未来地图生成受项目规则指导，而不是重复手工调 prompt。

## 当前实现

活跃关卡：

- `res://data/levels/level_001.json`
- `style_id`: `stormwind_city_v3`

生成的 path-guide style：

- `res://data/map_styles/stormwind_city_v3.json`
- `res://assets/tilesets/stormwind_city_v3/background_frame.png`
- `res://assets/tilesets/stormwind_city_v3/background_frame_normal.png`

生成道路已烘焙进 `background_frame.png`。`BoardMapRenderer` 保持玩法 path slots 不变，用于移动和放置；但它不再在上层绘制 road overlay tiles。

工具：

- `game/tools/generate-road-guide.py`
- 默认输出：`game/tools/out/road_guides/<level_id>/`
- 输出目录被 git 忽略，因为生成的 guide 图片是 review 产物。

## 流水线

### 1. 从玩法数据生成 Guide

使用 `level_001.json` 作为事实来源：

- grid size: `10 x 8`
- board image size: `1280 x 1024`
- cell size: `128`
- path cells:

```text
(0,3) -> (1,3) -> (2,3) -> (3,3) -> (4,3)
                                      |
                                    (4,4) -> (5,4) -> (6,4) -> (7,4) -> (8,4) -> (9,4)
```

guide generator 会绘制：

- 从路径中心线生成的 road body mask。
- body 周围的 curb mask。
- 可选 shadow mask。
- 带清晰颜色的可见 guide preview：
  - 奶油色道路主体。
  - 蓝色 curb 区域。
  - 红色敌人中心线。

guide 必须由代码生成，不能手画。这样能保证 guide 匹配玩法 `path_cells`。

当前命令：

```bash
game/tools/generate-road-guide.py \
  --overlay-image res://assets/tilesets/stormwind_city_v3/background_frame.png
```

生成文件：

- `road_body_mask.png`
- `road_curb_mask.png`
- `road_curb_ring_mask.png`
- `road_shadow_mask.png`
- `road_guide_preview.png`
- `road_guide_annotated.png`
- `game_path_overlay.png`
- `road_guide_manifest.json`

### 2. 生成风格化棋盘图

使用图像生成，并让 guide 作为可见布局参考。

Prompt 要求：

- 精确保留 guide 中的道路路线、道路宽度、圆角转弯、入口边和出口边。
- 将道路主体转换为浅暖色石板路。
- 将 curb 区域转换为凸起白石边界，并带少量边缘装饰。
- 移除 guide 标记：不要红色中心线、不要蓝色 overlay 色、不要标签、不要点。
- 不添加额外道路、分支、路口、UI、文字、logo 或角色。
- 保持相同的 top-down / slightly 3/4 棋盘视角。

生成图片会作为背景候选。它不允许改变玩法数据。

### 3. 标准化并集成

将生成图片标准化到棋盘资产尺寸：

```text
1280 x 1024
```

放到新的 style 目录下：

```text
game/assets/tilesets/stormwind_city_v3/
├── background_frame.png
└── background_frame_normal.png
```

创建专用 style JSON：

```text
game/data/map_styles/stormwind_city_v3.json
```

style JSON 应只指向 baked background 和 normal map。路径和可建造地形已属于背景的一部分，因此该 style 不定义语义化 road tile 映射。

这样能让运行时加载保持简单，同时避免重复绘制道路和透明 placeholder 资产。

### 4. 切换关卡

对活跃关卡设置：

```json
"style_id": "stormwind_city_v3"
```

位置：

```text
game/data/levels/level_001.json
```

## 为什么更好

- 路径形状来自游戏数据，因此生成图片有更强的空间目标。
- 生成结果可以像手绘一样整体一致，不像小 tile atlas 那样有明显重复。
- 现有玩法路径、塔放置、目标选择和敌人移动都不变。
- 该工作流兼容未来确定性 road-ribbon renderer。guide/mask generator 可以变成该 renderer 的 preview/bake 工具。

## 验证

必需检查：

- `LevelDefinition.style_id` 指向 `stormwind_city_v3`。
- `MapStyleDefinition` 可以加载生成的 style。
- `BoardMapRenderer` 可以加载生成背景和 normal 贴图。
- 地图渲染不依赖 road overlay、透明 placeholder 或语义化 tile 资产。
- `game/tools/test-gut.sh` 通过。

当前验证：

```text
128/128 GUT tests passing
```

## 已知限制

- 道路几何被视觉烘焙进一张图片。修改 `path_cells` 需要重新生成 guide 和图片。
- 图像生成仍可能偏离 guide。生产质量应强制 mask，或使用确定性 road-ribbon renderer。
- 因为道路是背景的一部分，path tile overlay 已禁用。未来任何 blocked/locked/road overlay polish 都应考虑这种 style mode。

## 与 Road Ribbon Rendering 的关系

这是用于快速评估的短期美术工作流。

更长期的工程方向仍是：

- 从 `path_cells` 生成道路几何。
- 用生成的 pavement/curb 材质填充。
- 用程序验证宽度和转弯半径。

该方向记录在：

```text
docs/designs/2026-05-09-road-ribbon-rendering-and-asset-contract.md
```
