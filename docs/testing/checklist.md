# Testing Checklist

## Before Implementing A Gameplay Rule

- [ ] Write the rule inputs, outputs, and failure reasons.
- [ ] Add a failing GUT test before implementation.
- [ ] Confirm the test does not depend on real frame rate.
- [ ] Inject a fixed seed when randomness is involved.

## Before Completing A Feature

- [ ] Core GUT tests pass.
- [ ] Godot headless startup passes.
- [ ] New or changed rules have tests.
- [ ] Bug fixes include a regression test.
- [ ] Relevant documentation is updated.

## Manual Playtest Notes

- [ ] The first wave makes placement and tower progression understandable.
- [ ] The first 3 minutes have clear decisions.
- [ ] Failure reasons are understandable.
- [ ] Tower progression feedback is clear.
