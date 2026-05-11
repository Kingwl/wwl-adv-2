# 项目状态

## 当前里程碑

里程碑 1：Playable Prototype 已完成；里程碑 2：MVP 准备已开始。

可玩循环已经具备：玩家可以开始、放塔、升级、拆除、战斗、获胜或失败。MVP 目前主线是内容数据化和更长可演示局。

## 已验证命令

最近检查：2026-05-11。

```bash
cd game
./tools/agent-preflight.sh
./tools/agent-preflight-full.sh
./tools/check-assets.sh
./tools/test-gut.sh
./tools/check-docs.sh
./tools/check-ui-smoke.sh
./tools/generate-ui-visual-review.py --artifact-dir ../ci-artifacts/ui-smoke/native --block-size 4
./tools/check-gameplay-smoke.sh
./tools/check-level-grid-audit.sh
./tools/generate-map-layout-guide.py
./tools/compose-map-grid-layer.py --level res://data/levels/level_002.json --level res://data/levels/level_003.json --level res://data/levels/level_004.json --write-clean-background --write-style-assets
./tools/compose-map-grid-layer.py --level res://data/levels/level_005.json --write-style-assets
for level in level_001 level_002 level_003 level_004 level_005; do ./tools/generate-map-visual-review.py --level "res://data/levels/${level}.json" --block-size 4; done
./tools/generate-map-visual-review.py --level res://data/levels/level_005.json --block-size 4
./tools/generate-map-visual-review.py --level res://data/levels/level_005.json --block-size 2
./tools/check-all.sh
```

当前已知测试状态：

- Godot: 4.6.2 stable.
- GUT: 9.6.0.
- GUT 套件：218 个测试通过，1617 个断言。
- Asset check：5 个关卡、5 个 map style、3 类敌人、6 个 wave set、48 个波次、5 座塔和 1 份经济配置通过。
- Native UI smoke：桌面、移动横屏和方形视口通过，每个视口 18 个 review crop；截图、局部 crop、overlay 和 4x4 visual-review contact sheet 位于 `ci-artifacts/ui-smoke/native/`。
- Native gameplay smoke：11 个代表性 gameplay scenario 通过，trace、截图、board overlay 和 focus overlay 位于 `ci-artifacts/gameplay-smoke/native/`。
- Level grid audit：5 个关卡通过逐格放置规则、全可建造格塔展示和路径敌人展示检查；当前可建造格数量为 35/19/20/24/15，截图、board crop 和 overlay 位于 `ci-artifacts/level-grid-audit/native/`。
- Map layout guide：5 个关卡生成模型参考图、background reference、grid-layer reference、annotated 图、语义 mask、contract 和技术 prompt fragment，产物位于 `game/tools/out/map_layout_guides/`。
- Map visual review：5 个关卡生成源图 contact sheet、preview crop atlas 和 4x4 的 `nearest`、Pillow `BOX`、自实现 `mean` / `median` 降采样对比图；Level 5 还保留 2x2 细节对比，全关卡运行时 4x4 摘要位于 `game/tools/out/map_visual_review/all-levels-runtime-4x4-summary.png`。产物位于 `game/tools/out/map_visual_review/level_*/`。
- Web export smoke：Web 导出页面通过本地 HTTP + headless browser 检查，报告和截图位于 `ci-artifacts/web-smoke/`。
- Structural lint：Tree-sitter GDScript 解析 105 个文件，0 个 error，0 个 warning。
- Agent preflight fast：运行 `check-all.sh`，生成 Godot/GUT 结构化日志报告，不运行 native smoke。
- Agent preflight full：运行 fast preflight、native UI smoke、native gameplay smoke 和 UI smoke 摘要。
- 已知警告：GUT 退出时有来自场景/资源清理的 ObjectDB leaked instances 警告，记录为 TD-007。

## 已实现

- Godot 4.x 项目骨架和 GUT 配置。
- 可测试的 `game/scripts/core/` 规则层。
- 棋盘放置、移除、保留格和路径校验规则。
- 经济钱包、放置费用、击杀奖励和波次清空奖励；默认经济配置位于 `game/data/economy/economy.json`。
- 敌人路径移动、生命值、死亡事件和漏怪处理。
- 固定 tick 战斗模拟。
- 塔配置数据文件、注册表、目标选择、攻击冷却、投射物生成、投射物移动和命中检测。
- 波次生成和波次清空事件。
- 玩家生命、胜利和失败状态。
- 开始场景、主场景、暂停菜单、重开、返回开始、胜利和失败流程。
- 五种基础塔：Single、Area、Slow、Flame 和 Poison，定义位于 `game/data/towers/towers.json`，包括建造费用、塔/投射物/命中特效资源引用，并由 `game/data/schemas/towers.schema.json` 和 `check-assets.sh` 校验。
- 点击已放置塔会显示右上角浮动操作菜单，支持直接升级和拆除。
- 塔选择卡组通过 `TowerPresentationCatalog` 从塔配置生成；HUD 按钮和数字键按 tower id 选择塔，`U` 升级选中塔，`X`/`Delete`/`Backspace` 拆除选中塔，`Esc` 优先关闭塔操作菜单再进入暂停。
- 塔升级效果按塔类型和 tier 配置化；普通升级只做数值提升，每次升级必须提升伤害和攻击范围；升级不清空攻击冷却，只会按新攻击间隔钳制剩余冷却。
- 塔操作菜单显示下一次升级预览，包含伤害和范围成长。
- 攻击、防御、伤害类型和种族抗性第一版已进入核心伤害结算；现有五塔的武器形态、攻击类型、伤害类型、攻击模式、投射物速度和视觉资源从塔数据文件加载。
- 通用状态和 DoT 第一版已进入核心战斗：塔 tier 通过 `effects[]` 表达即时伤害、溅射伤害和附加状态；Slow 会作为状态实际降低敌人移动速度，Flame 会施加 Burn DoT，Poison 会施加 Poison DoT，Burn/Poison 类 DoT 可按完整 tick interval 产生携带攻击/伤害类型的 `DamageEvent` 并继续走伤害克制结算。
- 拆除塔会返还 50% 建造和升级累计投入。
- 五种基础塔在棋盘和塔卡中使用生成的圆形塔顶 sprite，运行时按当前目标方向旋转；Flame 塔、Poison 塔和对应命中特效使用本地生成的新素材。
- 当前地图的数据驱动关卡路径/style/blocked mask 加载。
- 地图 layout guide 生成工具：`game/tools/generate-map-layout-guide.py` 可从关卡 JSON 生成模型参考图、background reference、grid-layer reference、annotated 图、语义 mask、contract 和技术 prompt fragment，用于重生成分层地图前固定一格外圈景观、中间矩形空地、内部可建造区和路径。
- 地图 deterministic grid layer 合成工具：`game/tools/compose-map-grid-layer.py` 可从关卡 JSON 和现有 image-generated 背景纹理生成 clean playfield 背景、透明 `grid_layer_composed.png`、flattened preview 和 manifest；Level 2-5 已接入运行时 map style，其中 Level 2-4 使用外圈 image-generated 场景加中场确定性石板空地，Level 5 使用 clean citadel courtyard 背景。
- 地图视觉审查工具：`game/tools/generate-map-visual-review.py` 可对背景、grid layer、preview、buildable-grid 和 path-enemies 截图生成固定语义 crop，并用可配置 `--block-size` 输出 `nearest`、Pillow `BOX`、自实现 `mean` 和 `median` 降采样对比。
- Map style 支持可选 `grid_layer` 全棋盘覆盖图，以及 `tiles.buildable/path/blocked/locked` 逐 slot overlay；`BoardMapRenderer` 先画 background，再画 `grid_layer`，最后画逐 slot tile。
- 敌人定义位于 `game/data/enemies/enemies.json`，包含 speed、health、kill reward、armor/race 和伤害类型抗性 override；波次定义位于 `game/data/waves/`，按关卡 `wave_set_id` 选择 wave set 并按 enemy type 引用敌人配置。
- 五个 MVP 关卡第一版已落地：`level_001` 到 `level_005` 分别引用 Training Gate、Long Road、Kill Zone、Armored Column 和 MVP Showcase 的 8 波 wave set；`level_001` 使用 `stormwind_city_v3`，`level_002` 到 `level_005` 使用 Long Road、Kill Zone、Armored Column 和 MVP Showcase 的差异化路径和 authored blocked cells，避免塔放到水面、城墙、屋顶或装饰物上。Level 2-5 当前使用 clean background + deterministic grid layer，road、buildable pad 和 interior blocker 都由关卡 JSON 合成。
- 生成的城市防御地图、四张 MVP 关卡地图、道路 guide 产物、UI frame、塔 sprite、敌人 sprite 和攻击特效。
- 覆盖 start-to-main 可玩性、响应式视口、单塔放置、塔操作菜单和截图产物的 native UI smoke。
- UI visual review 工具：`game/tools/generate-ui-visual-review.py` 从 native UI smoke report 生成 4x4 合 1 的整屏 contact sheet、关键 crop contact sheet 和逐视口 crop atlas；`check-ui-smoke.sh` 会自动调用它，极窄 crop 的边缘 block 会使用实际可用像素参与均值，避免小 crop 阻断 smoke 门禁。
- 覆盖放塔、升级/拆除返还、Single 击杀奖励、Area 溅射、Slow 状态、Flame 灼烧 DoT、Poison 中毒 DoT、逐塔视觉目录、漏怪、胜利和失败的 native gameplay smoke。
- 覆盖五个 MVP 关卡的 level grid audit：逐格断言可建造/不可建造规则，全可建造格放塔截图、blocked/path overlay，以及路径敌人截图。
- 逐塔视觉目录通过 `TowerPresentationCatalog` 从塔配置自动发现 `visual_test_enabled` 的塔，并为每种塔产出塔本体、投射物飞行中、命中/效果出现后的整屏截图、board crop、focus crop 和辅助线 overlay。
- Tree-sitter structural lint，覆盖 core/scene/render 边界、BoardView 资产加载边界和结构回膨胀 warning 报告。
- `BoardAssetCatalog`，集中管理主棋盘场景的关卡、map style、HUD 图标、敌人 sprite 和特效贴图加载；塔本体、投射物和命中特效资源从 `TowerConfig` 读取。
- `BoardGameSession`，集中管理一局游戏的棋盘、钱包、放置服务、战斗模拟、波次、奖励和胜负 flow；场景测试和 smoke runner 通过 `BoardView.get_session()` 明确访问。
- `BoardLayoutService`、`BoardHudController`、`BoardInputAdapter`、`BoardVisualState`、`BoardRenderer` 和 `TowerPresentationCatalog`，分别承接主棋盘响应式布局、HUD/overlay 同步、输入路由、表现层动画状态、绘制 adapter 和塔卡/smoke 展示清单。
- HUD status/hint 通过 `BoardMessage` 输出结构化状态码、参数、完整文案和紧凑文案；紧凑视口不再依赖英文文案前缀或 `get_slice()` 解析。
- `BoardView` 不再保留 session、layout、asset 或 visual state 的兼容镜像字段；场景测试和 smoke runner 通过显式 getter 访问拆出的边界。
- `BoardMapRenderer` 已从 `game/scripts/core/` 迁到 `game/scripts/board/`，core 目录下渲染/资源加载耦合现在由 structural lint 作为 error 阻止。
- `TowerConfig` 的 JSON 加载/原始解析、语义校验和 UI/smoke 展示清单已拆到 `TowerDefinitionParser`、`TowerDefinitionValidator` 和 `TowerPresentationCatalog`；`TowerConfig` 保留运行时读取 API、tower id lookup 和 parser/validator 委托入口。
- `TowerConfig` 现在以 tower id 作为 roster 主键，并提供 ID-first stats、费用、升级、展示和视觉资源读取 API；核心放置、攻击、投射物事件、HUD 塔卡和资产 catalog 已能按 tower id 读取非 `GameTower.Type` 枚举塔定义。
- 用于本地 agent 迭代反馈的 agent preflight 和 UI smoke 摘要脚本。
- Godot/GUT 日志结构化报告，输出到 `ci-artifacts/godot-log/report.json` 和 `report.md`。
- Web export smoke，验证 Godot Web 导出页面 canvas 非空且无关键浏览器错误，并作为 Pages 发布前门禁。
- 设计文档已收敛为当前架构聚合文档；历史细分设计归档到 `docs/designs/archive/`。
- 面向核心玩法规则、场景/UI 验证、截图视觉审查和 harness 维护的项目 Codex skills。
- 面向核心玩法和 UI 的功能清单与测试计划文档。

## 开放决策

- 敌人、波次和经济配置的数据形状第一版已实现；MVP 五关 8 波 wave set 已落地，后续需要长局平衡验证。
- 初期塔类型和实现批次已记录为 accepted design；火焰塔和毒针塔已进入代码和测试，雷霆塔等后续塔仍待实现。
- 塔机制、效果、状态、DoT 和视觉事件体系已记录为 accepted design；状态/DoT 核心规则、塔 `effects[]` 配置、Flame 灼烧塔和 Poison 毒针塔第一版已实现，雷霆塔和独立视觉事件仍未实现。
- 塔升级机制第一版已实现；未来是否加入分支进化仍待决定。
- 更长波次前，是否需要清理已完成/已击败但仍保留的敌人。
- 生成的 road ribbon 资产是否应变成确定性的运行时/编辑器生成内容。

## 已知风险

- 塔 roster 已让 schema、`check-assets.py`、HUD 按钮、数字键、smoke 选塔、核心放置和核心攻击按 tower id 走数据契约；`GameTower.Type` 仍作为现有五塔兼容标签存在于部分场景/渲染 fallback、颜色和旧合成测试中，记录为 TD-011 的剩余边界。
- `TowerConfig` 已拆出 loader/parser/validator/presentation catalog，并删除旧 tier/effect fallback；仍保留部分 enum/default 映射以支撑现有五塔兼容路径，记录为 TD-011/TD-012 的剩余边界。
- `BoardRenderer`、`BoardHudController` 和 `test_main_scene.gd` 仍是体积最大的维护点，记录为 TD-015 和 TD-017。
- 当前敌人和波次已数据化，但只有三类基础敌人；MVP 五关已有第一版差异化地图、路径和 blocked mask，仍缺实现后的长局平衡快照和玩家可选关卡入口。Level 2-5 已切到 clean background + deterministic grid layer；后续长局平衡需要确认每关可建造密度是否合适。
- Level 1 仍使用旧 `stormwind_city_v3` baked background；如果它也需要和 Level 2-5 保持同一分层视觉语言，还需要生成 clean background + deterministic grid layer。
- 测试质量依赖 GUT 加 checklist，而不是行覆盖率。
- 场景测试当前会输出 ObjectDB leak 警告，记录为 TD-007。

## GitHub 自动化

- CI workflow：`.github/workflows/ci.yml`。
- CI 运行 `check-all.sh`、native UI smoke 和 native gameplay smoke；`check-all.sh` 包含关卡、map style、塔配置资产/schema 检查和 Tree-sitter structural lint。
- CI 将 `check-all.log` 解析为 Godot/GUT 结构化报告。
- CI 将 `ci-artifacts/` 上传为 `godot-check-artifacts` artifact。
- GitHub Pages workflow：`.github/workflows/pages.yml`。
- Pages 来源：GitHub Actions workflow 从 `site/` 加 `_site/play/` 下的 Godot Web 导出进行部署。
- Pages 发布前运行 Web export smoke，并上传 `ci-artifacts/web-smoke/` 作为失败证据。
- 本地 Web 导出默认输出到 Godot 项目目录外的 `build/web/`。
- 项目 skills 版本化存放在 `.codex/skills/`；本地 Codex runtime 不会自动加载仓库内 skills 时，将它们链接到 `$CODEX_HOME/skills`。

## 下一步最值得做的工作

1. 为 Level 5 增加长局 gameplay smoke 或 headless balance summary，记录金币、生命、漏怪、胜负和最终波次。
2. 为 Level 2-5 增加可进入的关卡选择或 smoke 参数化入口，让新地图能被玩家路径和截图证据覆盖。
3. 在雷霆塔前收尾剩余 `GameTower.Type` 兼容边界：优先处理场景/渲染 fallback、颜色和旧合成测试中的 tower-type match。
