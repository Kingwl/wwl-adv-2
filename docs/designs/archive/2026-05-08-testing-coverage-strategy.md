# 设计：测试驱动和覆盖率策略

## 状态

Draft

## 决策

默认采用“GDScript 核心规则 + GUT 测试”的测试策略。

原因：

- 塔防合成游戏的高风险逻辑集中在战斗、合成、经济、波次和随机性上。
- 用户选择直接使用 GDScript，工程保持 Godot 原生开发体验。
- 核心规则仍要和场景节点分离，放在 `scripts/core/`，便于用 GUT 做快速测试。
- Godot 场景测试用于验证节点、信号、资源加载、动画触发和场景装配，不承担全部规则验证。

## 测试金字塔

```text
Manual Playtest
Scene / Integration Tests
Core Unit Tests
```

## 核心单元测试

范围：

- 合成规则。
- 塔属性、攻击冷却、索敌策略。
- 敌人移动和状态效果。
- 波次生成。
- 经济收支。
- 确定性随机。

要求：

- 每个新规则先写失败测试，再实现。
- 单测不能依赖 Godot 场景树。
- 同一输入和同一 seed 必须得到同一结果。
- 规则测试要覆盖正常路径、边界、失败原因。

## 场景和集成测试

范围：

- 主场景能启动。
- 地图资源能加载。
- 点击格子能触发放置意图。
- UI 数值能反映核心状态。
- 波次开始、结束、失败和胜利信号能正确派发。

测试工具：

- GUT 9.6.x，用于 Godot 4.6.x 的 GDScript 单元测试和集成测试。
- 不同时引入 GdUnit4，避免两套测试框架并存导致维护成本上升。

## 覆盖策略

GDScript 当前不采用强制行覆盖率门槛。质量门槛改为“关键规则测试覆盖清单 + GUT 测试通过”。

| Stage | Required Test Coverage |
| --- | --- |
| Prototype | 合成、棋盘放置、基础经济、基础战斗各有正常路径和失败路径测试。 |
| MVP | 波次、索敌、状态效果、胜负条件、主要 UI 状态同步都有测试。 |
| Beta | 每个已修复 bug 有回归测试；主要塔、敌人、关卡规则都有边界测试。 |

任何 bug 修复都要先补一个会失败的回归测试。

## 建议命令

当前命令：

```bash
cd game
./tools/check-all.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-docs.sh
```

实际命令以项目安装的 Godot 版本、插件版本和 CI 环境为准。

## CI 门禁

每个提交或 PR 至少执行：

- 文档结构检查。
- Godot headless 启动检查。
- GUT 测试。
- 新增或修改的核心规则有对应测试。

## 文件布局建议

```text
game/
├── project.godot
├── addons/
│   └── gut/
├── scenes/
├── scripts/
│   └── core/
├── assets/
└── test/
    ├── gut/
    └── godot/
```

## References

- Godot command line docs: https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html
- GUT command line docs: https://gut.readthedocs.io/en/9.3.1/Command-Line.html
