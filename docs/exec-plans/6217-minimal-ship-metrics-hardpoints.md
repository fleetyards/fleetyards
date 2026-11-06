# Minimal metrics and hardpoints section on the ship page

Working plan for #6217. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The ship page opens on a short figures row and a compact hardpoint list, with the full section one click away and metrics cards collapsible per ship.

## What changed

### Phase 1 — Reduce the hardpoint tree to rows
1. Share the group column layout between the full and the minimal list.
2. A pure function turns a group's hardpoints into categories of one-line rows.

### Phase 2 — The minimal section
1. One row component, with the item tooltip and a single figure.
2. The section: figures panel above the group cards.
3. The toggle on the ship page, remembered in the models store, and its locale keys.

### Phase 3 — Collapsible metrics cards
1. MetricsCard folds to its title when the ship page asks for it, per ship.
2. Each metrics card names itself.

## Intent Verification

- [ ] A named component's row opens its item tooltip and links to the catalogue
- [ ] The rows add up to the figures above them
- [ ] The choice of view survives a reload; a collapsed card survives a reload and applies to that ship only
- [ ] The loadout page renders as before

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Models/HardpointsMinimal/` | The minimal section and its rows |
| `app/frontend/frontend/components/Models/Hardpoints/columns.ts` | Group column layout shared with the full list |
| `app/frontend/frontend/components/Models/MetricsCard/index.vue` | Collapse |
| `app/frontend/frontend/stores/models.ts` | The remembered view; closed sections per ship |
| `app/frontend/frontend/pages/ships/[slug]/index.vue` | The toggle |

## Discovery Log

- **2026-11-06** Initial research and plan creation. Design chosen on the canvas linked from the issue.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
