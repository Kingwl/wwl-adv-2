# Design: Merge UI Integration

## Status

Deferred. Keep this as a reference option until the Prototype progression model is decided.

## Context

Core merge rules already exist in `TowerMergeService`: two towers can merge only when they are different instances with the same type and same tier. Board rules also define the MVP merge position: the merged tower stays in the first selected tower's grid cell, and the second tower's cell is cleared.

`BoardView` currently treats every left click as a placement attempt. Clicking an occupied slot returns an occupied-placement failure, so the core merge rule is not reachable from the playable scene.

As of 2026-05-09, implementation is paused because the project has not committed to merge versus direct tower upgrade as the Prototype's tower progression model.

## Goals

- Add scene-level merge interaction without introducing drag-and-drop.
- Keep merge mutation testable in the core layer instead of embedding it in `BoardView`.
- Make valid merge targets obvious after selecting a tower.
- Keep empty-grid placement behavior unchanged.
- Keep tower-card selection for future placements independent from merge selection.
- Preserve deterministic combat state after a merge.

## Non-Goals

- No drag merge in Prototype.
- No tower movement.
- No gold cost or refund for merging.
- No random summon probabilities in this step.
- No merge animation beyond highlight/status feedback in the first implementation.

## Proposal

Use a two-click merge flow:

1. Click an occupied buildable slot to select that tower as the merge source.
2. Highlight the selected tower and all compatible merge targets.
3. Click a compatible occupied slot to merge it into the source slot.
4. Click an incompatible occupied slot to switch the source selection to that tower and show a short hint.
5. Click the selected source again, press Escape, restart, pause, or return to start to clear merge selection.
6. Click an empty buildable slot to place a tower as today and clear any merge selection.

The merged tower stays at the source position. The clicked target tower is consumed. Tower-card selection remains the selected type for new placements; it does not change when selecting a tower on the board.

## Core Service

Add a small orchestration service outside the scene:

```text
game/scripts/core/placement/
├── tower_merge_placement_service.gd
└── tower_merge_placement_result.gd
```

`TowerMergePlacementService` owns board and registry mutation:

```text
try_merge_positions(source_position: Vector2i, target_position: Vector2i) -> TowerMergePlacementResult
```

Responsibilities:

- Validate both positions are in bounds.
- Validate both slots contain towers.
- Resolve both tower ids through `TowerRegistry`.
- Call `TowerMergeService.try_merge(source_tower, target_tower)`.
- On success:
  - remove source and target ids from `TowerRegistry`;
  - clear the target board slot;
  - replace the source board slot occupant with the merged tower id;
  - set `merged_tower.grid_position = source_position`;
  - add merged tower to `TowerRegistry`;
  - return consumed ids and merged id.

The service should return structured failure reasons for scene feedback:

```text
NONE
SOURCE_OUT_OF_BOUNDS
TARGET_OUT_OF_BOUNDS
SOURCE_EMPTY
TARGET_EMPTY
SOURCE_TOWER_MISSING
TARGET_TOWER_MISSING
SAME_TOWER
TYPE_MISMATCH
TIER_MISMATCH
BOARD_UPDATE_FAILED
```

Existing `TowerMergeResult.FailureReason` should be preserved and mapped into the placement-level result instead of duplicated in `BoardView`.

## Board API

Prefer adding one explicit board helper instead of mutating slot internals from scene code:

```text
replace_tower(position: Vector2i, expected_occupant_id: String, new_occupant_id: String) -> PlacementResult
```

Rules:

- Position must be in bounds.
- Slot must currently contain `expected_occupant_id`.
- New occupant id must be non-empty.
- Slot type must still be buildable.

This keeps the merge service atomic enough for MVP: validate both slots, replace source, clear target, then update the registry. If a board update fails, no scene UI should guess at recovery.

## BoardView State

Add scene state only for interaction and drawing:

```text
var merge_source_position := INVALID_GRID_POSITION
var merge_source_tower_id := ""
var last_merge_result: TowerMergePlacementResult
var merge_feedback_elapsed_seconds := 0.0
```

Add helpers:

```text
has_merge_source() -> bool
clear_merge_source() -> void
select_merge_source(position: Vector2i) -> void
try_merge_with_source(target_position: Vector2i) -> TowerMergePlacementResult
is_compatible_merge_target(position: Vector2i) -> bool
```

`BoardView._unhandled_input()` should route left clicks through one method:

```text
handle_board_click(grid_position)
```

Click routing:

- Out of bounds: call placement path or show existing invalid feedback.
- Empty slot: clear merge selection and call `try_place_at_grid()`.
- Occupied slot with no merge source: select source.
- Occupied selected source: clear source.
- Occupied compatible target: call merge service.
- Occupied incompatible target: select the clicked tower as the new source and show why it cannot merge with the previous source.

After a successful merge:

- Clear merge selection.
- Call `_sync_combat_towers()`.
- Clear tower attack animation entries for consumed tower ids.
- Keep existing projectiles alive; projectile damage already carries its own tower type and damage.
- Update status with the merged type and tier.
- Redraw.

Merged towers reset cooldown because `TowerMergeService` creates a new `GameTower`. This is acceptable for Prototype and should be noted as a balancing choice.

## Visual Feedback

Use lightweight drawing in `BoardView` before adding dedicated nodes:

- Selected source: bright gold outline around the source slot.
- Compatible targets: cyan or green outline around matching occupied slots.
- Incompatible occupied hover while source selected: red outline.
- Successful merge: brief pulse at the source slot.
- Failed merge: status text plus red outline at the target slot.

Tower sprites should show tier without requiring new art immediately. First pass:

- Draw a small tier badge in the top-right of the slot for `tier > 1`.
- Keep tower type sprite unchanged.
- Later art can add tier-specific sprites or shader tinting.

HUD copy:

- Source selected: `Selected Single T1. Pick another Single T1 to merge.`
- Success: `Merged tower-1 + tower-2 into Single T2.`
- Incompatible: `Area T1 cannot merge with Single T1.`
- Same tower: `Select a different tower to merge.`

## Tests

Add tests before scene wiring.

Core tests:

- Same type and tier at two occupied positions merge into the source position.
- Target position is cleared after success.
- Registry removes consumed ids and registers the merged tower.
- Different types fail without board or registry mutation.
- Different tiers fail without board or registry mutation.
- Empty source fails.
- Empty target fails.
- Missing registry tower fails.
- Same position fails.

Scene tests:

- Clicking an occupied slot selects merge source without spending gold.
- Clicking a compatible occupied slot merges and keeps wallet unchanged.
- Merged tower appears at the first selected slot.
- Target slot becomes empty.
- Combat simulation tower list is resynced after merge.
- Clicking empty slot while a source is selected places normally and clears merge source.
- Restart clears merge source and last merge result.

## Implementation Order

1. Add `Board.replace_tower()` and GUT tests.
2. Add `TowerMergePlacementResult`.
3. Add `TowerMergePlacementService` and core GUT tests.
4. Add `BoardView` merge source state and click routing.
5. Add selection/target highlight drawing.
6. Add tier badge drawing.
7. Add scene tests for source selection and successful merge.
8. Mark Milestone 1 `二合一合成` complete when tests pass.

## Alternatives

- Drag-and-drop merge: more direct on desktop, but worse for mobile landscape and requires pointer capture, drag preview, and cancellation states.
- Dedicated merge mode button: less accidental, but adds an extra mode and competes with the tower-card bar.
- Auto-merge on placing onto occupied slot: too easy to confuse with placement failure and does not let the player inspect possible targets.

## Risks

- Occupied-slot clicks changing from placement failure to selection will alter one existing scene test. Update it to assert the new selection behavior instead of occupied placement failure.
- Replacing source/target ids in board and registry must remain consistent. Keep mutation in the core service and assert no partial mutation on failure paths.
- Tier badge text can clutter small mobile cells. Only draw it for `tier > 1` and keep the badge size tied to `cell_size`.

## Open Questions

- Should a successful merge reset cooldown permanently for Prototype, or inherit the lower cooldown of the consumed towers?
- Should incompatible target clicks switch source selection, or keep the old source and show an error only?
- Should merge success create a small gold cost later for economy pacing?
