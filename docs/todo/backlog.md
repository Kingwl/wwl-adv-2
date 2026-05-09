# Backlog

## Now

- [ ] Decide Prototype tower progression model: merge or direct upgrade.
- [ ] Evaluate deterministic road ribbon rendering for future editable path maps.
- [ ] Add normal maps for tower, enemy, projectile, and impact sprites and wire them into 2D lighting.

## Next

- [ ] Design random tower summon probabilities after the tower progression model is chosen.
- [ ] Design real projectile entities if attacks should have travel time before damage.
- [ ] Add enemy cleanup service if retained enemies affect long-run performance.

## Later

- [ ] Add data-driven tower and wave configuration.
- [ ] Add additional tower families and status effects.
- [ ] Add balancing fixtures and simulation snapshots.
- [ ] Add simple save data for settings and progression.
- [ ] Add road material generation contract and validator for generated pavement/curb assets.

## Done

- [x] Create documentation folders.
- [x] Document Godot 2D tower defense merge direction.
- [x] Document TDD and coverage strategy.
- [x] Design board grid rules.
- [x] Design economy resource system.
- [x] Design enemy path movement.
- [x] Design tower types and framework.
- [x] Create a Godot 4.x project skeleton under `game/`.
- [x] Create `scripts/core/` as a testable GDScript rule layer.
- [x] Choose GUT as the Godot/GDScript test framework.
- [x] Add GUT test command.
- [x] Write merge-rule tests and implementation for same-type same-tier tower merging.
- [x] Implement board slot placement rules with GUT tests.
- [x] Implement board removal rules with GUT tests.
- [x] Implement board path validation with GUT tests.
- [x] Implement BoardView skeleton and grid rendering.
- [x] Connect scene grid clicks to `Board` through `BoardView`.
- [x] Add hover and invalid-click feedback for BoardView.
- [x] Add first scene/integration test for main scene loading.
- [x] Implement basic economy rules for placement costs.
- [x] Integrate gold display and placement cost into BoardView.
- [x] Implement enemy path progress rules with GUT tests.
- [x] Render moving enemy placeholder in BoardView.
- [x] Implement tower config and stats with GUT tests.
- [x] Implement targeting service for FIRST targeting.
- [x] Implement basic tower attack events.
- [x] Connect placed board occupants to runtime tower objects.
- [x] Implement single enemy health and death events.
- [x] Implement fixed tick combat simulation.
- [x] Connect enemy death events to wallet rewards.
- [x] Connect combat simulation to BoardView runtime loop.
- [x] Design wave system.
- [x] Implement wave spawning.
- [x] Integrate wave spawning into `CombatSimulation`.
- [x] Add wave clear reward hooks.
- [x] Connect wave spawning to BoardView enemy rendering.
- [x] Add wave HUD state.
- [x] Add Godot headless startup check.
- [x] Design victory and failure conditions.
- [x] Add player life / leak handling.
- [x] Implement victory and failure state in `CombatSimulation`.
- [x] Add Lives HUD and victory/defeat status in BoardView.
- [x] Document enemy lifecycle policy for completed/defeated enemies.
- [x] Add responsive mobile landscape layout for BoardView.
- [x] Render simple attack feedback from `CombatTickResult`.
- [x] Render enemy health bars from current and max health.
- [x] Generate MVP v1 tower, enemy, projectile, and impact sprite assets.
- [x] Wire MVP v1 sprites into BoardView tower, enemy, and attack feedback rendering.
- [x] Replace visual-only attack feedback with core projectile movement and hit detection.
- [x] Generate Stormwind-inspired baked raster city defense map asset and metadata.
- [x] Generate MMO v1 tower attack and enemy walk/death animation sprite assets.
- [x] Wire MMO v1 tower and enemy sprites into BoardView with attack, walk, and death animation playback.
- [x] Wire Stormwind-inspired city defense map as the BoardView background.
- [x] Replace free-form board background with a grid-aligned map contract and runtime image.
- [x] Replace prototype aligned board art with a Stormwind-inspired aligned runtime background.
- [x] Add separate start scene, pause menu, win/lose overlays, restart, and return-to-start flow.
- [x] Add scene tower type selection for Single, Area, and Slow towers.
- [x] Upgrade tower selection to a fixed tower-card bar with price, selected, paused, and unaffordable states.
- [x] Add data-driven level definition and semantic Stormwind-style tile renderer prototype.
- [x] Replace repeated cut-tile prototype with generated background-frame plus transparent road-overlay map style.
- [x] Add road guide generation tool for mask, guide, and gameplay path overlay artifacts.
- [x] Promote generated path-guide map style from preview naming to `stormwind_city_v3`.
- [x] Remove transparent road tile placeholders from baked-road map style.
- [x] Remove semantic road tile styles, assets, renderer branch, and tests.
- [x] Add Prototype rule coverage checklist under `docs/testing/`.
