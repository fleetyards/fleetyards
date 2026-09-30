# Loadout stats: mount turn rate and DPS by control group

Working plan for #5185. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Gimbal and turret rows show their turn rate in °/s, and the Combat card splits DPS by pilot, manned turret, remote turret and point defence.

## What changed

### Phase 1 — Parser
1. `SCItemTurretParams.movementList` joints give a top speed per axis; slaved joints are ignored.
2. Control from the mount: `PDCTurret`/`PDC` tag → pds, `remoteTurret` params → remote, `MannedTurret` or a seat → manned, otherwise nothing (pilot).

### Phase 2 — API
1. `ComponentTurret` in the `typeData` anyOf, `ComponentTurretControlEnum` from `Component::TURRET_CONTROLS`.

### Phase 3 — Frontend
1. `useHardpointStats`: turn rate (primary) and control on turret/weapon-mount rows.
2. `computeLoadoutStats`: `dpsByControl`, outermost mount decides; Combat card bar when any non-pilot group has DPS.

## Intent Verification

- [x] **Asgard** — PC2 dual mount 35 °/s, VariPuck 80 °/s, bubble turret manned (checked against a scratch re-parse of 4.10.1-live).
- [x] **Parse diff** — a scratch items re-parse differs from the current tree only in the 397 mounts' `yaw_speed`/`pitch_speed`/`control`.

## Not in scope (deferred)
- **Re-parse and push the live/ptu trees** — `bin/scdata push` is an outward action on the shared bucket that production reloads from; left to the maintainer.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
