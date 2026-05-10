# Backlog

## 现在

- [ ] 决定 Prototype 塔成长模型：合成或直接升级。
- [ ] 评估确定性 road ribbon 渲染，用于未来可编辑路径地图。
- [ ] 为塔、敌人、投射物和命中特效 sprite 添加 normal map，并接入 2D lighting。

## 下一步

- [ ] 塔成长模型确定后，设计随机召唤塔的概率。
- [ ] 如果攻击应在造成伤害前有飞行时间，设计真实投射物实体。
- [ ] 如果保留的敌人影响长期运行性能，添加敌人清理服务。

## UI 问题

- [x] 主界面顶部 HUD 的 status/hint 文案在移动横屏视口被 Menu 区域截断，在方形视口贴近或覆盖棋盘上缘；需要拆成独立 toast/提示区，或为紧凑视口提供更短文案/ellipsis。
- [x] 主界面应居中的文字没有统一显式设置水平/垂直居中；需要让标题、overlay 文案、status/hint 和按钮文字显式居中，并保留塔卡图标文字左对齐作为设计例外。
- [x] 主界面资源栏的 Gold/Lives/Wave 文字虽然在 Label 内垂直居中，但整行 rect 在 HUD 饰框里偏上；需要下移资源行，让文字视觉中心贴近槽位中心。
- [x] 移动横屏的奖励 status 文案在侧栏消息区被截断；需要为 `Defeated`、`Cleared` 和 `Earned` 奖励状态提供紧凑短文案。
- [x] Web 导出启动页标题中的中文字符渲染成方框；需要改用 Web 可用字体或避免启动页使用缺字中文。

## 稍后

- [ ] 添加数据驱动的塔和波次配置。
- [ ] 添加更多塔系和状态效果。
- [ ] 添加平衡性 fixture 和模拟快照。
- [ ] 为设置和进度添加简单存档数据。
- [ ] 为生成的路面/路缘资产添加道路材质生成契约和校验器。

## 已完成

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
- [x] 为 GitHub Pages 可玩构建添加 Godot Web 导出流水线。
