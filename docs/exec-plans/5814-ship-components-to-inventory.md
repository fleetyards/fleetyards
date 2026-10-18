# Ship components as their own pledge item category, with add-to-inventory actions

Working plan for #5814. Decisions live in the issue body. Deleted before the PR merges.

## Goal

The hangar sync keeps the ship parts RSI lists (coolers, power plants, weapons, …) as a "Ship components" pledge item list, linked to the component catalogue where it can be, and each one, or a selection of them, can be added to an inventory.

## Open questions

- **Catalogue link.** Proposed: a nullable `component_id` on `hangar_pledge_items`, set by the sync. Paints link through a join table because one paint fits several hulls; a ship component names one catalogue item, so a column is enough.
- **Adding twice.** Should a pledge item remember that it was added to an inventory (and to which), so "add all" skips it and the row says so? Without it, a second "add all" doubles the stock.
- **Bulk add.** Proposed: a new `POST /api/v1/hangar/inventories/:slug/items/bulk` that writes all deposits in one transaction, instead of the browser sending one request per item, so a failure leaves nothing half-added.
- **Other kinds.** Should FPS gear get the same per-item and bulk actions? The ledger already accepts `Equipment`, but FPS gear has no stored catalogue link today (the sync only answers yes/no).
- **Modules vs ship components while reading.** The extension reports both as `component`. The sync modal needs to tell them apart before the server sees them. Proposed: every mapped module name ends in "Module", so the modal counts a `component` named "… Module" as a module and the rest as ship components. The server stays the authority for what is stored.
- **Inventory category.** Proposed: the catalogue's `weapons`, `weapon_mounts` and `turret` categories become the ledger's `weapon`, everything else `component`; an unmatched item is `component`.

## What changed

### Phase 1 — Store ship components
1. `HangarPledgeItem::KINDS` gains `component`; migration adds `component_id` (nullable FK to `components`) and its index.
2. `HangarPledgeItems::Sync` takes RSI `component` items that `HangarModuleMapping` does not know, as kind `component`, and links each to the catalogue by name.
3. `HangarSync#sync_components` stops at mapped modules only; the run reports the stored ship components (`synced_components`) in its output, like paints and flair.
4. `imports.sync_ship_components` column (default true), the sync settings flag, the API input and `pledge_item_kinds`.

### Phase 2 — List them
1. `GET /api/v1/hangar/components` on `HangarPledgeItemsController` (shared `list` scope), with the catalogue item (name, slug, category, size, grade) in the jbuilder and schema.
2. `pages/hangar/components.vue` → `PledgeItemsPage` with `kind="component"`; a tab in `PledgeItemsSwitch`; route and nav titles.
3. The row shows the catalogue type and size where matched.

### Phase 3 — Add to inventory
1. `Logistics/InventoryItemModal` accepts a preselected item (name, category, item type and id, quantity), so a row can open it already filled in; the user picks the inventory.
2. A row action "Add to inventory" on ship components.
3. Bulk selection on the list (`useBulkSelection` + `BulkSelectionBar`) with "Add to inventory", and "select all" across the page.
4. The bulk endpoint (see open question) and its request spec.

### Phase 4 — Sync modal
1. The read list counts modules and ship components as separate kinds; the result list adds "Ship components".
2. The last-read summary (`Imports::HangarSync#read_summary`) splits the two the same way, so the comparison per kind holds.

## Intent Verification

- [ ] **A sync of a hangar with coolers and weapons stores them** — they appear in the Ship components list, not dropped, and the import's output names them.
- [ ] **Matched items carry their catalogue type** — a Sovereign IP-10 shows as a power plant.
- [ ] **Switching the setting off leaves stored ship components alone** — as the other kinds do.
- [ ] **Add one** — the row action opens the inventory modal filled in; saving adds a deposit referencing the catalogue component.
- [ ] **Add many** — selecting items and choosing "Add to inventory" adds one deposit each, in one request.
- [ ] **Sync modal** — modules and ship components count separately while reading and in the result.
- [ ] **Copy in all seven locales.**

## Key files

| File | Role |
|------|------|
| `app/lib/hangar_sync.rb` | `sync_components` drops unmapped names today |
| `app/lib/hangar_module_mapping.rb` | the module names the sync knows |
| `app/lib/hangar_pledge_items/sync.rb` | stores paints, flair, FPS gear, CCUs |
| `app/models/hangar_pledge_item.rb` | `KINDS`, scopes |
| `app/controllers/api/v1/hangar_pledge_items_controller.rb` | the lists' endpoints |
| `app/models/concerns/inventory_ledger_entry.rb` | ledger item types and categories |
| `app/controllers/concerns/inventory_scoped/item_actions.rb` | inventory entry create/import |
| `app/frontend/frontend/components/Hangar/PledgeItemsPage`, `PledgeItemsList`, `PledgeItemsSwitch` | the lists |
| `app/frontend/frontend/components/Logistics/InventoryItemModal` | the only entry creator |
| `app/frontend/shared/composables/useBulkSelection.ts`, `shared/components/BulkSelectionBar` | bulk selection |
| `app/frontend/frontend/components/Hangar/SyncBtn/Result` | the sync modal's read and result lists |

## Not in scope (deferred)

- **Fitting a ship component onto a ship's loadout** — the hangar has no per-vehicle loadout to write to.

## Discovery Log

- **2026-10-18** Initial research and plan. On a real hangar, 22 of 27 RSI "component" items were ship parts the sync dropped; a quick name probe found most in the component catalogue.

## Progress

- [ ] Phase 1 — Store ship components
- [ ] Phase 2 — List them
- [ ] Phase 3 — Add to inventory
- [ ] Phase 4 — Sync modal
