# Backlog

## 现在

- [ ] 继续清理剩余 `GameTower.Type` 兼容边界，重点是场景/渲染 fallback、颜色和旧合成测试中的 tower-type match。
- [ ] 评估是否将 Level 1 也切到 clean background + deterministic grid layer，和 Level 2-5 保持同一分层视觉语言。
- [ ] 为塔、敌人、投射物和命中特效 sprite 添加 normal map，并接入 2D lighting。

## 下一步

- [ ] 为 MVP Showcase 增加长局 gameplay smoke 或 headless balance summary，覆盖金币、生命、漏怪、胜负和最终波次。
- [ ] 为 Level 2-5 增加可进入的关卡选择或 smoke 参数化入口，让新地图能被玩家路径和截图证据覆盖。
- [ ] 塔成长模型确定后，设计随机召唤塔的概率。
- [ ] 如果攻击应在造成伤害前有飞行时间，设计真实投射物实体。
- [ ] 如果保留的敌人影响长期运行性能，添加敌人清理服务。
- [ ] 拆分 `test_main_scene.gd` 的 HUD、输入、布局、overlay 和流程断言，沉淀共享场景 fixture helper。
- [ ] 收敛 tower schema、`check-assets.py` 和 `TowerConfig.validate_definitions()` 的重复枚举与语义校验规则。

## UI 问题

- [x] Level 1 grid audit 中部分可建造格视觉上落在水面、城墙边缘或装饰区域；已补 authored blocked cells，并通过逐格审计确认。
- [x] Level 2 grid audit 中部分可建造格视觉上落在河道、屋顶、树丛或市场装饰区域；已补 authored blocked cells，并通过逐格审计确认。
- [x] Level 3 grid audit 中部分可建造格视觉上落在城墙、攻城器械、围栏或训练场装饰区域；已补 authored blocked cells，并通过逐格审计确认。
- [x] Level 4 grid audit 中部分可建造格视觉上落在城墙、屋顶、兵营物件或防御工事区域；已补 authored blocked cells，并通过逐格审计确认。
- [x] Level 5 grid audit 中部分可建造格视觉上落在水渠、城堡入口、雕像或外墙装饰区域；已补 authored blocked cells，并通过逐格审计确认。
- [x] Level 5 新生成背景首次接入后，旧 authored path/buildable cells 与图中 S 形道路和塔台错位；已按新背景重对齐 `level_005` 的路径、出口和 blocked cells。
- [x] Level 5 deterministic grid layer 首版叠在旧 baked 道路背景上，且左侧可建造格与护城河/城墙视觉冲突；已改用 clean background-only 底图、左右出入口背景和重排后的 15 个可建造塔台。
- [x] Level grid audit board crop 顶部仍露出一条被裁切的 HUD/status 文案，影响地图截图审查；已去掉 board crop 的顶部 HUD 外扩，只保留左右和底部审查余量。
- [x] Level 2 composed grid layer preview 直接叠在 baked 城市背景上，半透明矩形塔台覆盖原有道路、水渠、花坛和建筑边缘，不能作为运行时 grid layer 直接接入；已生成 clean playfield 背景并接入 deterministic grid layer。
- [x] Level 2 runtime buildable cells 缺少统一的塔台视觉标记，塔放在普通广场、花坛边和桥头铺装上时，玩家很难在放塔前判断哪些格子可建造；已用统一 buildable pad 层表达可建造区。
- [x] Level 3 composed grid layer preview 直接叠在已有军营道具和围栏背景上，矩形塔台覆盖器械、木架和防御平台，视觉语义混杂；已生成 clean playfield 背景并接入 deterministic grid layer。
- [x] Level 3 runtime buildable cells 和场景里的防御平台/器械道具距离过近，部分塔基看起来像压在装饰物或障碍物上；已将中场玩法区清空为确定性地面，由 blocker/pad 层表达规则。
- [x] Level 4 composed grid layer preview 与 baked 背景中已有的方形塔台重复表达，形成两套不同透明度和材质的可建造语言；已生成 clean playfield 背景并接入 deterministic grid layer。
- [x] Level 4 runtime buildable cells 一部分有明确石质塔台，一部分只是普通泥地或兵营空地，建造 affordance 不一致；已用统一 buildable pad 层表达可建造区。
- [x] Level 5 右下大块空石板区域没有塔台但视觉上仍像可建造地面，需要为非可建造空地增加明确的景观/障碍/材质差异；已让 deterministic grid layer 为内部 blocked cells 画 blocker 标记。
- [ ] Level 5 deterministic road 在左入口和右出口处仍像半透明铺色块直接切出画面，没有和城门、桥或边界景观自然衔接。
- [x] Level 5 buildable pads 仍偏 UI overlay 感，尤其与同材质石板底面叠加时不够像地图原生平台；已改为更低饱和石质 tint 和更弱描边。
- [x] Level 2 clean background 第一版重复铺出绿色斑块，4x4 采样下像规律污渍；已改为低对比、低频石板地面。
- [x] Level 2-4 clean background 第二版逐格亮度变化形成规则棋盘感，容易被误读为玩法格；已改为连续小尺度石板纹理，不按玩法格对齐。
- [x] 移动横屏顶部 status/hint 两行文字虽然未裁切，但在 4x4 审查和原图 crop 中都显得贴近上下装饰边框，整体过于拥挤；已为 compact inline 消息使用更矮行高、更小字号和更轻描边。
- [x] 桌面和移动横屏右侧塔卡的中心装饰线、宝石和边框穿过或贴近塔名/描述/价格文字，4x4 审查下文字层级和卡框装饰混在一起；已将右侧竖排塔卡改为无内部装饰线的深色卡面，保留图标、选中态和外层 HUD 框。
- [x] UI smoke 的 start-screen crop 在 desktop、mobile-landscape 和 square 下尺寸和内容一致，无法作为开始页响应式视觉证据；已补 `*-start-screen-full.png` 全视口 crop，并纳入 4x4 visual-review。
- [x] 移动横屏五塔侧栏中，选中态塔卡的九宫格上下装饰压到 Poison 标题文字；已减小塔卡贴图上下边距，并让紧凑塔卡用普通框加金色文字表达选中。
- [x] 移动横屏的塔放置预览 smoke crop 被裁成 2x2 像素，无法人工审查；已改用 canvas transform 计算棋盘局部 crop。
- [x] 塔放置 hover 预览消失，棋盘上只剩 hover 边框；已恢复当前选中塔的半透明预览并加入 UI smoke crop 覆盖。
- [x] 塔操作菜单关闭后，右侧 hint 仍保留 `Upgrade or remove this tower.` 截断文案；已在关闭菜单时恢复当前塔卡选择提示。
- [x] 塔操作菜单的横向 `Upgrade 40g` / `Remove +12g` 按钮在 smoke crop 中被按钮框裁切；已改为纵向全宽按钮。
- [x] 箭塔分层原型的 top 素材仍带一圈独立石质平台，运行时需要缩放和上移才贴合塔身；已改为单张圆形旋转塔顶并删除分层原型。
- [x] 主界面顶部 HUD 的 status/hint 文案在移动横屏视口被 Menu 区域截断，在方形视口贴近或覆盖棋盘上缘；需要拆成独立 toast/提示区，或为紧凑视口提供更短文案/ellipsis。
- [x] 主界面应居中的文字没有统一显式设置水平/垂直居中；需要让标题、overlay 文案、status/hint 和按钮文字显式居中，并保留塔卡图标文字左对齐作为设计例外。
- [x] 主界面资源栏的 Gold/Lives/Wave 文字虽然在 Label 内垂直居中，但整行 rect 在 HUD 饰框里偏上；需要下移资源行，让文字视觉中心贴近槽位中心。
- [x] 移动横屏的奖励 status 文案在侧栏消息区被截断；需要为 `Defeated`、`Cleared` 和 `Earned` 奖励状态提供紧凑短文案。
- [x] Web 导出启动页标题中的中文字符渲染成方框；需要改用 Web 可用字体或避免启动页使用缺字中文。

## 稍后

- [ ] 添加更多塔系和状态效果。
- [ ] 添加平衡性 fixture 和模拟快照。
- [ ] 为设置和进度添加简单存档数据。
- [ ] 为生成的路面/路缘资产添加道路材质生成契约和校验器。

## 已完成

- [x] 将 HUD status/hint 从自由文本解析改为 `BoardMessage` 结构化状态码/presentation model，以稳定紧凑视口文案。
- [x] 实现 MVP 五关 wave set 数据契约和第一版 8 波节奏。
- [x] 为 Level 2-5 生成并接入 Long Road、Kill Zone、Armored Column 和 MVP Showcase 四张 baked map style 与差异化路径。
- [x] 添加地图 layout guide 生成工具，用关卡 JSON 先生成图像模型参考图，固定外圈不可建造区、内部可建造区和路径。
- [x] 地图生成流水线改为支持分层输入：background reference 只约束固定一格外圈景观和中间矩形空地，grid-layer reference 约束格子、路径和内部阻挡，runtime map style 支持可选 `grid_layer` 和逐 slot overlay。
- [x] 添加 deterministic grid layer compositor，并将 Level 5 接入 clean background-only 底图加关卡 JSON 合成 road/pad 覆盖层。
- [x] 拆分 `TowerConfig` 的 UI/smoke presentation spec，并清理已被 `effects[]` 取代的 legacy tier/effect fallback。
- [x] 将塔 roster 主键推进到 tower id：schema 和 `check-assets.py` 不再枚举固定五塔 type，核心配置、放置、攻击、投射物事件、HUD 塔卡和资产 catalog 支持按 tower id 读取非 `GameTower.Type` 塔定义。
- [x] 创建文档目录。
- [x] 记录 Godot 2D 塔防合成方向。
- [x] 记录 TDD 和覆盖策略。
- [x] 设计棋盘格规则。
- [x] 设计经济资源系统。
- [x] 设计敌人路径移动。
- [x] 设计塔类型和框架。
- [x] 在 `game/` 下创建 Godot 4.x 项目骨架。
- [x] 创建 `scripts/core/` 作为可测试的 GDScript 规则层。
- [x] 选择 GUT 作为 Godot/GDScript 测试框架。
- [x] 添加 GUT 测试命令。
- [x] 编写并实现同类型同等级塔合成的合成规则测试。
- [x] 用 GUT 测试实现棋盘格放置规则。
- [x] 用 GUT 测试实现棋盘移除规则。
- [x] 用 GUT 测试实现棋盘路径校验。
- [x] 实现 BoardView 骨架和格子渲染。
- [x] 通过 `BoardView` 将场景格子点击连接到 `Board`。
- [x] 为 BoardView 添加 hover 和非法点击反馈。
- [x] 添加首个主场景加载的场景/集成测试。
- [x] 实现放置费用的基础经济规则。
- [x] 将金币显示和放置费用集成进 BoardView。
- [x] 用 GUT 测试实现敌人路径进度规则。
- [x] 在 BoardView 中渲染移动敌人占位。
- [x] 用 GUT 测试实现塔配置和属性。
- [x] 实现 FIRST 目标选择服务。
- [x] 实现基础塔攻击事件。
- [x] 将已放置棋盘占用者连接到运行时塔对象。
- [x] 实现单个敌人生命值和死亡事件。
- [x] 实现固定 tick 战斗模拟。
- [x] 将敌人死亡事件连接到钱包奖励。
- [x] 将战斗模拟连接到 BoardView 运行时循环。
- [x] 设计波次系统。
- [x] 实现波次生成。
- [x] 将波次生成集成进 `CombatSimulation`。
- [x] 添加波次清空奖励 hook。
- [x] 将波次生成连接到 BoardView 敌人渲染。
- [x] 添加波次 HUD 状态。
- [x] 添加 Godot headless 启动检查。
- [x] 设计胜利和失败条件。
- [x] 添加玩家生命/漏怪处理。
- [x] 在 `CombatSimulation` 中实现胜利和失败状态。
- [x] 在 BoardView 中添加 Lives HUD 和胜利/失败状态。
- [x] 记录已完成/已击败敌人的生命周期策略。
- [x] 为 BoardView 添加响应式移动横屏布局。
- [x] 从 `CombatTickResult` 渲染简单攻击反馈。
- [x] 根据当前和最大生命渲染敌人血条。
- [x] 生成 MVP v1 塔、敌人、投射物和命中特效 sprite 资产。
- [x] 将 MVP v1 sprite 接入 BoardView 的塔、敌人和攻击反馈渲染。
- [x] 用核心投射物移动和命中检测替换纯视觉攻击反馈。
- [x] 生成 Stormwind 风格 baked raster 城市防御地图资产和元数据。
- [x] 生成 MMO v1 塔攻击和敌人行走/死亡动画 sprite 资产。
- [x] 将 MMO v1 塔和敌人 sprite 接入 BoardView，并播放攻击、行走和死亡动画。
- [x] 将 Stormwind 风格城市防御地图接入为 BoardView 背景。
- [x] 用网格对齐地图契约和运行时图片替换自由形式棋盘背景。
- [x] 用 Stormwind 风格对齐运行时背景替换 prototype 对齐棋盘图。
- [x] 添加独立开始场景、暂停菜单、胜负 overlay、重开和返回开始流程。
- [x] 添加场景内 Single、Area 和 Slow 塔类型选择。
- [x] 将塔选择升级为固定 tower-card 栏，支持价格、选中、暂停和买不起状态。
- [x] 添加数据驱动关卡定义和语义化 Stormwind 风格 tile renderer prototype。
- [x] 用生成的 background-frame 加透明 road-overlay map style 替换重复切片 prototype。
- [x] 添加道路 guide 生成工具，生成 mask、guide 和 gameplay path overlay 产物。
- [x] 将生成的 path-guide map style 从 preview 命名提升到 `stormwind_city_v3`。
- [x] 从 baked-road map style 移除透明道路 tile placeholder。
- [x] 移除语义化道路 tile style、资产、renderer 分支和测试。
- [x] 在 `docs/testing/` 下添加 Prototype 规则覆盖 checklist。
- [x] 为关卡和 map style 数据添加 JSON/schema 资产检查。
- [x] 将塔定义推进到 `game/data/towers/towers.json`，并扩展 schema/effects 检查。
- [x] 将敌人、波次和经济配置推进到 `game/data/`，并扩展 schema/GUT/asset 检查。
- [x] 将塔建造费用和塔/投射物/命中特效资源引用推进到 `towers.json`，并让 `BoardAssetCatalog` 从塔配置加载。
- [x] 将 `TowerConfig` 的 JSON 加载、原始解析和语义校验拆到 `TowerDefinitionParser` / `TowerDefinitionValidator`。
- [x] 为 GitHub Pages 可玩构建添加 Godot Web 导出流水线。
- [x] 决定并实现 Prototype 塔成长模型：点击塔显示操作菜单，支持配置化升级和 50% 拆除返还。
