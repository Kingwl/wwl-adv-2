# 地图

## 当前运行时流水线

当前游戏棋盘使用由 path-guide 生成的 baked 背景。运行时地图渲染由关卡和 style 文件数据驱动：

- Level data: `res://data/levels/level_001.json`
- Style data: `res://data/map_styles/stormwind_city_v3.json`
- Generated map assets: `res://assets/tilesets/stormwind_city_v3/`

`BoardMapRenderer` 绘制一张生成的整棋盘背景 frame。可见道路由驱动敌人移动和放置限制的同一份 `path_cells` 烘焙进背景；语义化道路 overlay 资产不再是运行时路径的一部分。

## `stormwind_inspired_city_defense_aligned`

从之前的 `BoardView` 网格契约生成的旧版对齐背景，使用图像生成的 Stormwind 风格 high-fantasy 城市源图。

文件：

- `stormwind_inspired_city_defense_aligned.png`：1280x1024 运行时棋盘图片。
- `stormwind_inspired_city_defense_aligned.style_source.png`：图像生成的视觉风格源图。
- `stormwind_inspired_city_defense_aligned.prompt.txt`：prompt 和流水线记录。
- `res://data/maps/stormwind_inspired_city_defense_aligned.contract.json`：网格、格子和路径契约。

保留它用于参考。当前运行时路径使用通过 `stormwind_city_v3` 接入的 path-guide 生成整棋盘栅格图。

## `grid_aligned_city_defense`

较早的契约对齐 prototype 背景。保留它用于参考，但不再接入 `BoardView`。

文件：

- `grid_aligned_city_defense.png`
- `res://data/maps/grid_aligned_city_defense.contract.json`

## `stormwind_inspired_city_defense`

用 `generate2dmap` 生成为当前 10x8 塔防棋盘使用的 baked raster 地图。

文件：

- `stormwind_inspired_city_defense.png`：规范化后的 1280x1024 运行时地图图片。
- `stormwind_inspired_city_defense.raw.png`：原始生成图片副本。
- `stormwind_inspired_city_defense.prompt.txt`：生成时使用的 prompt。

元数据：

- `res://data/maps/stormwind_inspired_city_defense.manifest.json`
- `res://data/maps/stormwind_inspired_city_defense.collision.json`

这张地图是原创 high-fantasy 白石人类主城防御棋盘，包含蓝金旗帜、运河、大教堂尖塔和防御广场。它参考了用户要求的 Stormwind 氛围，但避免复制具体布局、logo、角色或徽章。
