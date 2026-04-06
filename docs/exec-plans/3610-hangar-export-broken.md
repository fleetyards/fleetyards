# Hangar Export broken

## Goal
Fix the JSON export download so it produces valid JSON instead of `[object Object]` strings.

## Context
Users report that the hangar export function produces broken output. The `axiosClient` returns parsed JavaScript objects, but the export functions pass these directly to `new Blob()` which calls `.toString()` on each object, producing `[object Object]` instead of valid JSON.

This affects all three export locations: hangar, wishlist, and fleet vehicles.

Resolves #3610

## Decisions

### D1 — Use JSON.stringify for Blob creation
Wrap the export data in `JSON.stringify(data, null, 2)` before creating the Blob. Pretty-printing with 2-space indent keeps the export human-readable, matching the expected JSON file output.

## What changed

### Phase 1 — Fix Blob creation in all export functions
1. `app/frontend/frontend/pages/hangar/index.vue` — wrap `exportedData` in `JSON.stringify`
2. `app/frontend/frontend/pages/hangar/wishlist.vue` — wrap `exportedData` in `JSON.stringify`
3. `app/frontend/frontend/components/Fleets/ShipsList/index.vue` — wrap `data` in `JSON.stringify`

## Intent Verification

- [ ] **Hangar export downloads valid JSON** — file contains proper JSON array of vehicle objects
- [ ] **Wishlist export downloads valid JSON** — same fix applied
- [ ] **Fleet export downloads valid JSON** — same fix applied

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/hangar/index.vue` | Hangar export UI + download logic |
| `app/frontend/frontend/pages/hangar/wishlist.vue` | Wishlist export UI + download logic |
| `app/frontend/frontend/components/Fleets/ShipsList/index.vue` | Fleet vehicles export UI + download logic |
| `app/frontend/services/axiosClient.ts` | HTTP client returning parsed JSON (root cause context) |

## Not in scope (deferred)
- **Extract shared export helper** — All three files duplicate the download logic; could be extracted to a shared composable, but not part of this bug fix.

## Discovery Log

- **2026-04-06** Initial research and plan creation. Root cause: `new Blob([parsedObject])` produces `[object Object]` strings.

## Progress
- [x] Phase 1
