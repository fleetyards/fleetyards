# Loadout editor: fill slots through sockets and a picker

Working plan for #5739. Decisions live in the issue body. Deleted before the PR merges.

## Goal

The loadout editor shows a ship's slots as sockets and fills the active one from a searchable, filterable picker beside it, with components that a weapons tab can reuse unchanged.

## Open questions

- None yet.

## What changed

### Phase 1 — Generic socket and picker components
1. `Loadout/Socket`: one slot — label, optional size, the fitted item (picture, name, figure) or a dashed empty state; active and just-filled states; a button.
2. `Loadout/SocketBoard`: sockets grouped under mount headings; `v-model:active` slot; arrow-key movement between sockets.
3. `Loadout/Picker`: title, search, filter chips (owned, stock, manufacturer), sort select, dense option rows (picture, name, manufacturer, badges, figure and delta), an "empty" choice, `preview`/`previewEnd`/`pick`/`close` events, Escape closes, a `#comparison` slot. Options are plain data (`LoadoutPickerOption`), nothing module-specific.
4. Specs for each, including a 90-option fixture for search, filters and sort.

### Phase 2 — Modules on the new components
1. A modules adapter (`useModuleSockets`): slots → socket groups by mount (front / rear / left / right, else one group), modules → picker options (owned / stock / not owned, manufacturer, cargo or bed figure, delta against what the socket holds).
2. `LoadoutModal` swaps `Fitting` for `SocketBoard` + `Picker`; the active socket replaces `pickedSlot`; the comparison renders in the picker's slot; a pick fills the socket and advances to the next empty one.
3. Read-only modal: sockets only, empty ones hidden, no picker.
4. Remove `Fitting` and its spec once nothing uses it.

### Phase 3 — Layout, motion, phone
1. Sockets over the backdrop on the left, picker in the right column (replacing the comparison column).
2. Fill animation on the socket; `prefers-reduced-motion` turns it off.
3. Phone width: sockets stack, the picker opens below the active socket.

### Phase 4 — Translations and checks
1. New keys in all seven locales by hand.
2. Check it in the browser on the Apollo, Retaliator and Aurora Mk II; screenshots for the PR.

## Intent Verification

- [ ] **Sockets** — every slot is a socket with label and fitted item or an empty state; grouped by mount.
- [ ] **Picker** — opens for the active socket, only its candidates; search, owned/stock/manufacturer filters and sort work with 90+ options.
- [ ] **Rows** — picture, name, manufacturer, ownership badge, figure and delta.
- [ ] **Preview** — hover or focus previews in the ship figures.
- [ ] **Fill** — picking fills the socket visibly and advances to the next empty one; the empty choice clears it.
- [ ] **Comparison** — lives in the picker.
- [ ] **Generic** — socket, board and picker import nothing module-specific.
- [ ] **Read-only** — visitors see filled sockets, no picker.
- [ ] **Keyboard** — sockets and rows reachable; Escape closes the picker.
- [ ] **Phone** — sockets stack; picker below the active socket.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.vue` | The editor; hosts the tabs, the ship figures and the modules tab |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.scss` | Editor layout over the backdrop |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/Fitting/index.vue` | Today's inline slot list, replaced |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/Comparison/index.vue` | Swap comparison, moves into the picker |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/moduleSlots.ts` | A hull's module slots |
| `app/frontend/frontend/composables/useLoadoutSlotLabel.ts` | Slot label from position keywords |
| `app/frontend/frontend/composables/useFittingDiff.ts` | Figures and deltas of a fitting |
| `app/frontend/frontend/components/Models/AddonOption/` | Row card the inline list used |

## Not in scope (deferred)

- **Weapons tab** — needs weapon hardpoints and candidates from the API, schema and fitting validation. Becomes its own issue before the PR merges.
- **Read view (`LoadoutView`) on sockets** — the marker's read view keeps its list for now. Becomes its own issue if the sockets read better there too.

## Discovery Log

- **2026-10-16** Initial research and plan creation. The dev catalogue holds 90 S1, 77 S2 and 90 S3 weapons; module slots hold 2–4 candidates. Hardpoint positions on the ship picture are not derivable.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
