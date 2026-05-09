# 设计：网格对齐地图流水线

## 状态

Accepted

## 问题

之前的 baked 背景是自由形式插画。它使用了要求的城市防御氛围，但画出来的道路没有和玩法使用的精确网格契约共享同一数据。缩放或调色可以让某一区域对齐，但其他道路段会漂移，因为绘制路线没有被约束在格子边界上。

## 决策

`Board` 拥有唯一的玩法路径定义。运行时地图美术必须从数据生成：

- `res://data/levels/*.json` 定义棋盘尺寸、path cells、blocked cells、locked cells、spawn、exit 和 `style_id`。
- `res://data/map_styles/*.json` 将 `style_id` 映射到生成的 background frame 和可选 special-cell overlay 资产。
- `BoardMapRenderer` 将生成的 background frame 绘制到棋盘 rect 上。

活跃 map style 使用 path-guide 生成背景。可见道路从 `path_cells` 烘焙到背景中；敌人移动和塔放置仍以关卡数据作为事实来源。

## 当前路径契约

```text
(0,3) -> (1,3) -> (2,3) -> (3,3) -> (4,3)
                                      |
                                    (4,4) -> (5,4) -> (6,4) -> (7,4) -> (8,4) -> (9,4)
```

## 渲染规则

- 先绘制生成的整棋盘 background frame。
- 对普通可建造格，让背景透出，不重复绘制装饰地面 tile。
- 不绘制语义化 road overlay tiles 或替代色块。
- 只有显式配置资产时，才可绘制可选 blocked/locked overlays。
- 正常游玩中不绘制永久网格线。
- 在地图上层绘制 hover、非法放置、塔、敌人、投射物和血条。

## 验证

关卡 JSON 必须匹配：

- `BoardView.board.width`
- `BoardView.board.height`
- `BoardView.get_default_path()`
- `BoardView.get_map_style_definition().id`

这可以防止未来地图美术悄悄偏离玩法。

## 当前 Prototype

- 关卡：`res://data/levels/level_001.json`
- Style：`res://data/map_styles/stormwind_city_v3.json`
- Tileset：`res://assets/tilesets/stormwind_city_v3/`

这个 prototype 验证了 path-guide baked 流水线。后续 polish 应从 guide 重新生成背景，或迁移到确定性 road-ribbon 渲染，同时不改变玩法契约。
