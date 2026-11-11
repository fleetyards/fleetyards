# Hangar Planner: one docked panel for ship selection and routes

Working plan for #6281. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Every ship pick and route edit in the plan page happens in one panel docked on the right (a bottom sheet on phones), with Start / Route / End tabs per flow row.

## What changed

### Phase 1 — Flow emits one target

1. `HangarFlow` emits `open(target)` with the row key, the tab and every payload the row has (start, end, route, slot) instead of start/end/route/pick/edit.
2. `activeKey` prop highlights the row the panel is open for.

### Phase 2 — Panel shell and shared list

1. `ShipPanel/index.vue`: docked panel (desktop) / bottom sheet (< 992px), header, tabs, Esc, framed close, dirty confirm for the route.
2. `ShipPanel/ShipList`: grouped sections, search, sort, jump chips, keyboard (arrows, Enter), selected row, detail pane beside or inline.
3. `ShipPanel/ShipDetail`: image, specs, extra blocks, commit button.

### Phase 3 — Views

1. `StartView` from StartPickerModal, plus an out-of-reach section with reasons.
2. `EndView` from EndPickerModal; store ships are a section (UpgradeTargetModal goes).
3. `SlotView` from SlotShipsModal + CandidatePickerModal: shortlist compare and inline catalogue (model options API; price and cargo from the plan's store models).
4. `RouteView` from RouteModal: vertical step chain, stops between steps, totals and payment beside.

### Phase 4 — Wiring, removal, tests, locales

1. Plan page holds the panel target; suggestions page links to `?slot=<id>`.
2. Delete the six modals and their specs; specs for the views, ShipList, panel; HangarFlow spec on `open`.
3. Playwright `HangarPlanner.spec.ts` on the panel test id.
4. New keys in all seven locales.

## Intent Verification

- [ ] No picker opens a modal on top of another
- [ ] Tabs per row; the row stays visible and highlighted
- [ ] Grouped lists with search, sort and upgrade cost; detail pane; Enter commits
- [ ] Out-of-reach starts listed with a reason
- [ ] Slot shortlist compare + catalogue + save filters in one view
- [ ] Route steps edit, stops in between, totals and payment
- [ ] Bottom sheet below md

## Key files

| File                                                                   | Role                               |
| ---------------------------------------------------------------------- | ---------------------------------- |
| `app/frontend/frontend/components/Hangar/Planner/ShipPanel/`           | The panel, list, detail and views  |
| `app/frontend/frontend/components/Hangar/Planner/HangarFlow/index.vue` | Emits the panel target             |
| `app/frontend/frontend/pages/hangar/plans/[id].vue`                    | Holds and renders the panel        |
| `app/frontend/frontend/pages/hangar/plans/[id]/suggestions.vue`        | Opens a slot through the plan page |
| `test/playwright/e2e/HangarPlanner.spec.ts`                            | End-to-end planner flow            |

## Not in scope (deferred)

- **Route suggestions ("Ways there")** — already #5915.

## Discovery Log

- **2026-11-11** Initial research and plan creation. OffCanvas is a mobile overlay drawer that closes on any outside click, so the panel is its own component.
- **2026-11-11** Built. Slot settings stay SlotModal (see issue). The catalogue reads ModelOptions, which carry no price, so price and cargo come from the plan's store models where the ship is one.

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4 (Playwright left to CI)
