# Missiles and bombs: blast radius, lock cone, arm time, flight phases and bomb parsing

Working plan for #5316. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Missiles, bombs and missile racks carry their seeker, flight, fuse and launch figures from the game files through the API to their hardpoint rows.

## What changed

### Phase 1 — Parser
1. Missiles: lock cone, signal resilience, dumbfire, lifetime, boost/terminal phase, fuel, arm time, safety distance, blast radius.
2. Bombs: `SCItemBombParams` — damage, lifetime, drop angle, fuse.
3. Racks: launch delay, ignition on the pylon.

### Phase 2 — API
1. `ComponentMissile`, `ComponentBomb`, `ComponentMissileRack` in the `typeData` anyOf, plus a tracking signal enum.

### Phase 3 — Frontend
1. Missile, bomb and rack rows in `useHardpointStats`; labels in all 7 locales.

## Intent Verification

- [x] Parser carries the missile fields, rack launch delay and bombs — 232 items change against a baseline re-parse, only in the new keys
- [x] Documented schema components; pinned oasdiff reports no breaking change
- [x] Rows show them

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/items_parser.rb` | missile, bomb, rack parsing |
| `app/api_components/shared/v1/schemas/component_{missile,bomb,missile_rack}.rb` | schema |
| `app/frontend/frontend/composables/useHardpointStats.ts` | rows |

## Discovery Log

- **2026-09-30** Bombs already landed as `weapons` components with no typeData; racks as `missile_racks`/`bombcompartments`. `igniteOnPylon` exists on every rack.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
