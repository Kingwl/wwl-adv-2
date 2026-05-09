# Technical Debt Register

| ID | Area | Impact | Priority | Owner | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TD-001 | Testability | Gameplay rules coupled to Godot nodes would make unit tests slow and brittle. | High | TBD | Open | Keep combat, merge, economy, wave, and RNG rules in `scripts/core/`. |
| TD-002 | Coverage | GDScript line coverage is not as straightforward as .NET coverage. | High | TBD | Open | Use GUT test coverage checklists, branch/edge-case tests, and regression tests instead of line coverage gates. |
| TD-003 | Determinism | Frame-rate dependent combat simulation will create flaky tests and inconsistent balance. | High | TBD | Mitigated | Core combat uses fixed tick simulation; scene integration still needs to route through it. |
| TD-004 | Content Data | Hardcoded tower/wave values will make balancing and regression testing expensive. | Medium | TBD | Open | Move tower, enemy, and wave config into data resources after prototype rules stabilize. |
| TD-005 | Scene Tests | Too many scene tests can become slow and brittle. | Medium | TBD | Open | Keep most assertions in core tests; use scene tests only for integration boundaries. |
| TD-006 | Enemy Lifecycle | Completed and defeated enemies stay in the simulation array for now. | Low | TBD | Open | Add cleanup once longer waves or profiling show retained enemies affecting performance or scene rendering. |
