# 测试

这个目录存放持久测试策略和项目门禁。

## 文件

- `checklist.md`：规则、场景和手工测试的功能级 checklist。
- `gates.md`：代码和文档改动需要满足的验证门禁。
- `prototype-rule-coverage.md`：当前 Prototype 规则覆盖图。

核心玩法的功能级测试计划位于 `docs/gameplay/test-plan.md`；UI 的功能级测试计划位于 `docs/ui/test-plan.md`。

## 命令

优先使用聚合命令：

```bash
cd game
./tools/check-all.sh
```

仅文档改动：

```bash
cd game
./tools/check-docs.sh
```

玩法场景视觉/trace smoke：

```bash
cd game
./tools/check-gameplay-smoke.sh
```

架构边界和 BoardView 结构检查：

```bash
cd game
./tools/check-structure.sh
```
