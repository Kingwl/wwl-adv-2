# 里程碑计划

当前项目状态汇总在 `docs/status.md`。这个文件保留为历史 Milestone 0 bootstrap 检查点，不作为第二个实时状态来源。

## 当前里程碑

- 名称：Milestone 0 - Project Bootstrap
- 状态：完成
- 目标日期：TBD
- 负责人：TBD

## 范围

- 创建 Godot 4.x GDScript 项目。
- 构建可测试的 `scripts/core/` 规则层。
- 添加 GUT 测试和 Godot headless 检查。
- 选择一个 Godot 场景测试插件。

## 完成标准

- 命令行可以运行 GUT 测试。
- Godot 项目可以在 headless 模式启动。
- 首个 TDD 流程完成：失败的合成规则测试、实现、测试通过。

## 风险

- Godot 场景逻辑可能泄漏到核心规则中，降低可测试性。
- 纯 GDScript 实现会让严格代码覆盖率更难做。
- 测试纪律必须通过规则覆盖 checklist 和回归测试来约束。

## 进度

- [x] 记录玩法方向和测试策略。
- [x] 创建 Godot 项目骨架。
- [x] 添加 GUT 测试项目。
- [x] 运行 Godot headless 启动检查。
- [x] 运行首批核心单元测试。
- [x] 添加 Godot 场景测试插件。
- [x] 将项目方向切换为 GDScript 优先。
