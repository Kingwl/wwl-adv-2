# 设计：地图和资产流水线

## 状态

Accepted

## 背景

当前地图从数据化关卡、map style、生成的 guide/mask 和 baked 背景共同组成。早期的网格对齐地图、path guide 生成和道路 ribbon 契约分别有设计文档；现在日常维护只需要一个当前流水线说明。

历史地图设计已归档到 `docs/designs/archive/`。未来确定性 road-ribbon renderer 仍保留独立设计：`docs/designs/2026-05-09-road-ribbon-rendering-and-asset-contract.md`。

## 当前契约

- `game/data/levels/*.json` 是玩法地图事实来源，定义棋盘尺寸、path cells、blocked cells、locked cells、spawn、exit 和 `style_id`。
- `game/data/map_styles/*.json` 将 `style_id` 映射到背景 frame、normal、可选 blocked/locked overlay 和视觉参数。
- `BoardAssetCatalog` 加载关卡、map style 和棋盘场景资产。
- `BoardMapRenderer` 在棋盘 rect 内绘制 baked background frame 和可选 overlay。
- 敌人移动、放置规则和地图视觉都必须遵循同一份关卡路径数据。

## 当前 Prototype

- 关卡：`res://data/levels/level_001.json`
- Style：`res://data/map_styles/stormwind_city_v3.json`
- Tileset：`res://assets/tilesets/stormwind_city_v3/`

这个 prototype 使用 path-guide baked 背景。正常游玩中不绘制永久网格线或语义化 road overlay tiles。

## 验证入口

- 资产/schema 检查：`cd game && ./tools/check-assets.sh`。
- 地图 GUT：`game/test/gut/maps/test_map_definitions.gd`。
- UI/gameplay smoke 截图：`ci-artifacts/ui-smoke/native/` 和 `ci-artifacts/gameplay-smoke/native/`。
- Web 导出：`cd game && ./tools/export-web.sh ../build/web`。

## 仍未解决

- 确定性 road-ribbon renderer 仍是未来工作。
- 多关卡 fixture 尚未扩展。
- 塔、敌人、波次和经济配置已迁移到数据文件并纳入资产/schema 检查；当前还需要覆盖更多关卡和长局平衡 fixture。
