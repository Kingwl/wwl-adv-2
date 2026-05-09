# Prototype Rule Coverage

This checklist tracks the expected rule coverage for the Playable Prototype.

| Area | Expected Coverage | Current State |
| --- | --- | --- |
| Board placement | Empty buildable, out of bounds, path, blocked, locked, occupied, reserved | Covered |
| Board removal | Success, empty slot, occupant mismatch | Covered |
| Path validation | Too short, out of bounds, non-path slot, diagonal, jump, valid path | Covered |
| Tower merge core | Same type/tier success, type mismatch, tier mismatch, same tower | Covered in core only |
| Tower progression UI | Player-facing merge or upgrade flow | Open decision |
| Economy wallet | Earn, spend, insufficient funds, invalid amount | Covered |
| Placement economy | Spend on success, no spend on invalid placement, no spend on insufficient gold | Covered |
| Enemy movement | Segment traversal, multi-segment traversal, completed/defeated stop, deterministic same input | Covered |
| Enemy damage/death | Damage, lethal damage, duplicate death prevention, unknown enemy damage | Covered |
| Targeting | FIRST target, no target, completed/defeated ignored, out of range ignored | Covered |
| Tower attack | Cooldown, no target, Single, Area, Slow projectile output | Covered |
| Projectile hit detection | Travel before hit, hit damage, area splash, slow status, miss inactive target | Covered |
| Wave spawning | Spawn interval, large delta, clear event, next wave, all waves cleared | Covered |
| Player life and leaks | Leak collection, life reduction, clamp to zero, failure | Covered |
| Victory/failure | Lives reach zero, all waves cleared with lives remaining | Covered |
| Scene flow | Start scene, main scene, pause, restart, win, lose | Covered |

## Open Coverage Gaps

- Tower progression is not reachable from the playable scene until merge versus direct upgrade is decided.
- Longer MVP content needs coverage for at least 3 enemy types and 8 waves.
- Scene tests currently emit an ObjectDB leak warning at process exit.
