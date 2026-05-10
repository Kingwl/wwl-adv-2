# 技术债登记表

| ID | 区域 | 影响 | 优先级 | 负责人 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| TD-001 | 可测试性 | 玩法规则耦合到 Godot 节点会让单元测试变慢且脆弱。 | High | TBD | Open | 将战斗、合成、经济、波次和 RNG 规则保留在 `scripts/core/`。 |
| TD-002 | 覆盖率 | GDScript 行覆盖率不像 .NET 覆盖率那样直接。 | High | TBD | Open | 用 GUT 测试覆盖 checklist、分支/边界测试和回归测试替代行覆盖率门禁。 |
| TD-003 | 确定性 | 依赖帧率的战斗模拟会制造 flaky 测试和不一致平衡。 | High | TBD | Mitigated | 核心战斗使用固定 tick 模拟；场景集成仍需通过它路由。 |
| TD-004 | 内容数据 | 硬编码敌人/波次数值会让平衡和回归测试变贵。 | Medium | TBD | Open | 塔定义已迁移到 `game/data/towers/towers.json`；后续继续迁移敌人和波次配置。 |
| TD-005 | 场景测试 | 过多场景测试会变慢且脆弱。 | Medium | TBD | Open | 大多数断言保留在核心测试；场景测试只用于集成边界。 |
| TD-006 | 敌人生命周期 | 已完成和已击败敌人目前仍保留在 simulation array 中。 | Low | TBD | Open | 当更长波次或 profiling 显示保留敌人影响性能或场景渲染时，再添加清理。 |
| TD-007 | 测试清理 | GUT 场景测试输出 `ObjectDB instances leaked at exit`，让 CI 输出变吵，也可能隐藏未来 leak 回归。 | Medium | TBD | Open | CI 上传 `check-all.log`；检查场景测试和 queued node/resource，移除该警告。 |
| TD-008 | 场景架构 | `BoardView` 曾同时承担 session、layout、HUD、input、visual state 和 renderer 职责。 | Medium | TBD | Mitigated | 兼容字段已清理；场景测试和 smoke runner 通过显式 getter 访问拆出的对象；`check-structure.sh` 继续用行数和函数数量防止回膨胀。 |
| TD-009 | 配置来源 | `BoardGameSession` 仍构造默认经济配置和波次定义。 | Medium | TBD | Open | 已从 `BoardView` 移出；后续将经济和波次迁移到数据或配置层。 |
| TD-010 | 渲染边界 | `BoardMapRenderer` 曾位于 core 目录并包含渲染/资源加载耦合。 | Medium | TBD | Mitigated | 已迁到 `game/scripts/board/`；core 下渲染和资源加载 API 现在由 `check-structure.sh` 作为 error 阻止。 |
