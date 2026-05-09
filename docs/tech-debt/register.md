# 技术债登记表

| ID | 区域 | 影响 | 优先级 | 负责人 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| TD-001 | 可测试性 | 玩法规则耦合到 Godot 节点会让单元测试变慢且脆弱。 | High | TBD | Open | 将战斗、合成、经济、波次和 RNG 规则保留在 `scripts/core/`。 |
| TD-002 | 覆盖率 | GDScript 行覆盖率不像 .NET 覆盖率那样直接。 | High | TBD | Open | 用 GUT 测试覆盖 checklist、分支/边界测试和回归测试替代行覆盖率门禁。 |
| TD-003 | 确定性 | 依赖帧率的战斗模拟会制造 flaky 测试和不一致平衡。 | High | TBD | Mitigated | 核心战斗使用固定 tick 模拟；场景集成仍需通过它路由。 |
| TD-004 | 内容数据 | 硬编码塔/波次数值会让平衡和回归测试变贵。 | Medium | TBD | Open | Prototype 规则稳定后，将塔、敌人和波次配置迁移到数据资源。 |
| TD-005 | 场景测试 | 过多场景测试会变慢且脆弱。 | Medium | TBD | Open | 大多数断言保留在核心测试；场景测试只用于集成边界。 |
| TD-006 | 敌人生命周期 | 已完成和已击败敌人目前仍保留在 simulation array 中。 | Low | TBD | Open | 当更长波次或 profiling 显示保留敌人影响性能或场景渲染时，再添加清理。 |
| TD-007 | 测试清理 | GUT 场景测试输出 `ObjectDB instances leaked at exit`，让 CI 输出变吵，也可能隐藏未来 leak 回归。 | Medium | TBD | Open | CI 上传 `check-all.log`；检查场景测试和 queued node/resource，移除该警告。 |
| TD-008 | 场景架构 | `BoardView` 仍然过大，混合布局、渲染、输入、流程和模拟集成。 | High | TBD | Open | `check-structure.sh` 已将行数和函数数量作为 warning；后续拆出 HUD、输入、渲染和 game flow adapter。 |
| TD-009 | 配置来源 | `BoardView` 仍构造默认经济配置和波次定义。 | Medium | TBD | Open | `check-structure.sh` 已作为 warning 跟踪；塔成长/平衡进入 MVP 后迁移到数据或配置层。 |
| TD-010 | 渲染边界 | `game/scripts/core/maps/BoardMapRenderer` 仍包含 `CanvasItem`、`Texture2D`、`CanvasTexture` 和资源加载。 | Medium | TBD | Open | 先保持为 warning，后续迁到场景/渲染 adapter，再收紧 core 边界规则。 |
