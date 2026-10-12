# Fleet events and missions: move hand-rolled labels and badges onto design-system primitives

Working plan for #5169. Decisions live in the issue body. Deleted before the PR merges.

## Goal

No component under `Fleets/Events` or `Fleets/Missions` carries its own uppercase label rule or hand-rolled badge.

## Open questions

- Badges: `Pill`, not `Chip`. `Chip` renders a `<button>` (it is the filter toggle); `bare` drops the frame. The static status badges get `Pill` with a variant, as `EventPanel` already does. `EventSlotRow`'s "you are here" keeps its bare `Chip`.
- The section heads (your signup, unassigned signups, the admins modal's three heads) take the row label too, rather than a `Heading`.

## What changed

### Phase 1: shared row label
1. `shared/components/rowLabel.scss`: `@mixin row-label` (Orbitron 11px, 0.16em, uppercase, `--color-text-dim`), extracted from RowListItem's `__badge-label`.
2. RowListItem uses it.

### Phase 2: labels
CalendarGrid day head, EventSlotRow type, EventSlotList and SlotList type badge, EventShipModal and ShipModal seat type, EventSlotPickerModal slot type, and the section heads of YourSignupPanel, UnassignedSignups and EventAdminsModal.

### Phase 3: position type text
`usePositionTypeLabel` composable: EventSlotRow and SlotList had it inline; EventSlotList, both ship modals and the slot picker print the raw enum value, which only read as words while uppercased.

### Phase 4: badges onto Pill
- YourSignupPanel status: confirmed → success, tentative → warning, the rest → neutral.
- EventAdminsModal role → default.
- EventSlotPickerModal current → default, taken → neutral.

### Phase 5: visual tests
YourSignupPanel (one per status) and UnassignedSignups on `visual-tests/events`.

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/components/RowListItem/index.scss` | source of the row label |
| `app/frontend/shared/components/base/Pill` | static badge |
| `app/frontend/frontend/pages/visual-tests/events.vue` | visual coverage |

## Discovery Log

- **2026-10-12** 10 components, 13 uppercase rules, 4 hand-rolled badges. Four call sites print `positionType` raw.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
