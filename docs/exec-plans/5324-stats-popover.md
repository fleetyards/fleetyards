# Stats popover: show a component's or item's stats card on hover, tap on touch

Working plan for #5324. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Hovering (or tapping, on touch) a named component or equipment item shows its stats card.

## What changed

### Phase 1 — Popover
1. `shared/components/StatsPopover`: trigger + teleported content slot, hover/focus/tap, one open at a time.

### Phase 2 — Cards
1. `StatsCard` with component and equipment variants, built on `useComponentStats` / `useEquipmentStats`.
2. `CatalogueItemLink`: a catalogue reference that fetches its card on first open.

### Phase 3 — Wiring
1. Hardpoint rows, blueprint rows/preview/page, stock item panel, contract progress.
2. `/visual-tests/overlays` demo.

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/components/StatsPopover/index.vue` | The popover |
| `app/frontend/frontend/components/StatsCard/` | The cards |
| `app/frontend/frontend/components/CatalogueItemLink/index.vue` | Lazy catalogue link |

## Not in scope (deferred)
- **Catalogue list rows** — the row is the item's own list entry and already carries its lead metric; not wired.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
