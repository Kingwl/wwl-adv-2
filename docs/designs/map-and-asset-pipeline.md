# 设计：地图和资产流水线

## 状态

Accepted

## 背景

当前地图从数据化关卡、map style、生成的 guide/mask、背景层和可选 grid layer 共同组成。早期的网格对齐地图、path guide 生成和道路 ribbon 契约分别有设计文档；现在日常维护只需要一个当前流水线说明。

历史地图设计已归档到 `docs/designs/archive/`。未来确定性 road-ribbon renderer 仍保留独立设计：`docs/designs/2026-05-09-road-ribbon-rendering-and-asset-contract.md`。

## 当前契约

- `game/data/levels/*.json` 是玩法地图事实来源，定义棋盘尺寸、path cells、blocked cells、locked cells、spawn、exit 和 `style_id`。
- `game/data/map_styles/*.json` 将 `style_id` 映射到背景 frame、normal、可选全棋盘 `grid_layer`、可选逐 slot overlay 和视觉参数。
- `BoardAssetCatalog` 加载关卡、map style 和棋盘场景资产。
- `BoardMapRenderer` 在棋盘 rect 内按顺序绘制 background、可选 `grid_layer` 和可选逐 slot overlay。
- 敌人移动、放置规则和地图视觉都必须遵循同一份关卡路径数据。
- 新地图生成前先运行 `game/tools/generate-map-layout-guide.py`，从关卡 JSON 生成确定性的 `layout_reference.png`、`background_reference.png`、`grid_layer_reference.png`、`layout_reference_annotated.png`、`layout_semantic_mask.png` 和 `layout_contract.json`。图像模型应以这些 reference 作为布局约束，而不是只依赖自然语言 prompt。

## 分层地图模型

新地图优先使用 `layered_raster`：

- background layer：整体场景底图，只负责外圈景观和中间固定尺寸空地。当前 10x8 棋盘的默认 reference 使用一格外圈和 8x6 中间空地；中间空地必须保持低细节、平坦、无道路、无塔台、无可建造暗示和无装饰物堆叠。
- grid layer：透明全棋盘覆盖图，盖在 background 之上，负责每关的 buildable cells、path cells、interior blocked cells 和 locked cells。路径转角、入口、出口和每关差异优先放到这一层。
- slot tiles：可选补充层，用 `tiles.buildable`、`tiles.path`、`tiles.blocked`、`tiles.locked` 为某类格子提供重复纹理；如果 full `grid_layer` 已经表达完整道路和格子，slot tiles 可以为空。

现有 baked 背景继续合法；当 map style 没有 `grid_layer` 或 slot tile 时，渲染结果保持原 baked background 行为。

## Deterministic Grid Layer Compositor

`game/tools/compose-map-grid-layer.py` 是分层地图的第一版确定性合成器。它读取 `game/data/levels/*.json` 和对应 map style，把现有 image-generated 背景作为外圈场景和纹理来源，但 clean playfield、路径 ribbon、可建造塔台和内部阻挡的几何全部从关卡 JSON 计算。脚本输出透明 `grid_layer_composed.png`、flattened `preview.png` 和 `composition_manifest.json`，默认产物位于 `game/tools/out/composed_map_layers/`；带 `--write-clean-background` 时会额外输出 `background_frame_clean.png`，带 `--write-style-assets` 时会把运行时 clean background / grid layer 写入 `game/assets/tilesets/<style_id>/`。

典型命令：

```bash
cd game
./tools/compose-map-grid-layer.py --level res://data/levels/level_002.json --level res://data/levels/level_003.json --level res://data/levels/level_004.json --write-clean-background --write-style-assets
./tools/compose-map-grid-layer.py --level res://data/levels/level_005.json --write-style-assets
```

这个方案避免让图像模型决定可建造格、道路转角、入口和出口。图像模型只负责提供可被采样或切片的美术质感；游戏语义仍由关卡 JSON 和合成器控制。

## Layout Guide 流水线

`generate-map-layout-guide.py` 将格子语义固定为：

- blue-gray：外圈景观，不可建造。它可以被画成城墙、水渠、屋顶、树林或其他边界装饰。
- green：内部可建造格，最终图里必须保持为平坦、清晰、可放塔的地面或塔台。
- cream：敌人路径，必须保持路线、出入口、宽度和转弯，不允许额外分支。
- brown/purple：内部阻挡或 locked cells，不可建造，可以画成装饰物、水池、废墟或防御工事。

默认命令：

```bash
cd game
./tools/generate-map-layout-guide.py
```

默认产物位于 `game/tools/out/map_layout_guides/<level_id>/`，该目录被 git 忽略，作为生成前 review 和图像模型输入使用。`layout_prompt_fragment.txt` 只提供技术约束；具体主题、艺术风格和镜头描述仍由使用 `generate2dmap` 的 agent 手写，避免脚本生成创意 prompt。

分层生成时优先使用：

- `background_reference.png` + `background_prompt_fragment.txt`：生成 background layer，只画固定一格外圈景观和中间矩形空地。
- `grid_layer_reference.png` + `grid_layer_prompt_fragment.txt`：生成透明 grid layer，只画格子、道路和内部阻挡，不画外圈景观。
- `layout_contract.json`：记录关卡、尺寸、语义计数、所有 cell 坐标、edge warning 和 guide 输出路径。

## 当前地图集

- `level_001` / Training Gate：`stormwind_city_v3`，目录 `res://assets/tilesets/stormwind_city_v3/`。
- `level_002` / Long Road：`long_road_v1`，目录 `res://assets/tilesets/long_road_v1/`。
- `level_003` / Kill Zone：`kill_zone_v1`，目录 `res://assets/tilesets/kill_zone_v1/`。
- `level_004` / Armored Column：`armored_column_v1`，目录 `res://assets/tilesets/armored_column_v1/`。
- `level_005` / MVP Showcase：`mvp_showcase_v1`，目录 `res://assets/tilesets/mvp_showcase_v1/`；当前背景为 clean citadel courtyard background-only 图，并接入 `grid_layer_composed.png` 作为确定性道路和成簇塔台覆盖层。

`level_001` 当前仍使用 baked 背景。`level_002` 到 `level_005` 已接入 clean background + deterministic grid layer，正常游玩中不绘制永久调试网格，但会显示由关卡 JSON 合成的道路、塔台和内部 blocker 覆盖层。后续重生成背景时，应优先维持分层：先用 `background_reference.png` 固定外圈景观和中间空地，再用 compositor 或 image-generated tile/texture source 生成可覆盖在棋盘 rect 上的透明 grid layer。

## 验证入口

- 资产/schema 检查：`cd game && ./tools/check-assets.sh`。
- 地图 layout guide：`cd game && ./tools/generate-map-layout-guide.py`。
- 确定性 grid layer 合成：`cd game && ./tools/compose-map-grid-layer.py --level res://data/levels/level_002.json --level res://data/levels/level_003.json --level res://data/levels/level_004.json --write-clean-background --write-style-assets`，以及 `./tools/compose-map-grid-layer.py --level res://data/levels/level_005.json --write-style-assets`。
- 地图 GUT：`game/test/gut/maps/test_map_definitions.gd`。
- UI/gameplay smoke 截图：`ci-artifacts/ui-smoke/native/` 和 `ci-artifacts/gameplay-smoke/native/`。
- Web 导出：`cd game && ./tools/export-web.sh ../build/web`。

## 仍未解决

- 确定性 grid layer compositor 已在 Level 2-5 配套 clean background 底图；Level 1 如需同一视觉语言，仍需要生成同类底图并接入 grid layer。
- 新地图目前是数据 fixture 和资产层接入；玩家可选关卡入口和 per-level 截图 smoke 仍待补。
- 塔、敌人、波次和经济配置已迁移到数据文件并纳入资产/schema 检查；当前还需要长局平衡 fixture。
