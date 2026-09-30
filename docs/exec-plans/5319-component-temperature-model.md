# Component heat reads a block 4.10 no longer ships

Working plan for #5319. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Components carry the 4.10 temperature model instead of the dead heat block, and the API exposes it.

## What changed

### Phase 1 — Parser
1. Drop the `EntityComponentHeatConnection` read; parse `SEntityPhysicsControllerParams/PhysType/*/temperature` when enabled.

### Phase 2 — Loader
1. Write the temperature into `heat_connection` on every load, clearing the old dumps.

### Phase 3 — API
1. `Component#temperature` filters known keys; `ComponentTemperature` schema; `temperature` on the component payload.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
