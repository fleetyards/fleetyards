# Ship components as their own pledge item category, with add-to-inventory actions

Working plan for #5814. Decisions live in the issue body. Deleted before the PR merges.

## Goal

The hangar sync keeps the ship parts RSI lists (coolers, power plants, weapons, …) as a "Ship components" pledge item list, linked to the component catalogue where it can be. Ship components and FPS gear can be added to an inventory one at a time or as a selection, and an item remembers where it went.

## Open questions

- **Modules vs ship components while reading.** The extension reports both as `component`, and the sync modal has to tell them apart before the server sees them. Proposed: every mapped module name ends in "Module", so the modal counts a `component` named "… Module" as a module and the rest as ship components. The server stays the authority for what is stored.
- **Inventory category.** Proposed: the catalogue's `weapons`, `weapon_mounts` and `turret` categories become the ledger's `weapon`; everything else is `component`, and FPS gear is `equipment`. An unmatched item takes its kind's default.

## What changed

### Phase 1 — Store ship components
1. `HangarPledgeItem::KINDS` gains `component`; a migration adds `component_id` and `equipment_id` (nullable FKs) with their indexes.
2. `HangarPledgeItems::Sync` takes RSI `component` items that `HangarModuleMapping` does not know, as kind `component`, and links each to the component catalogue by name.
3. `EquipmentCatalogue` returns the record it matched, not only yes or no, and the sync stores it as `equipment_id`.
4. `HangarSync#sync_components` handles mapped modules only; the run reports the stored ship components (`synced_components`) in its output, like paints and flair.
5. `imports.sync_ship_components` column (default true), the sync settings flag, the API input and `pledge_item_kinds`.

### Phase 2 — List them
1. `GET /api/v1/hangar/components` on `HangarPledgeItemsController` (shared `list` scope), with the catalogue item (name, slug, category, size, grade) in the jbuilder and schema.
2. `pages/hangar/components.vue` → `PledgeItemsPage` with `kind="component"`; a tab in `PledgeItemsSwitch`; route and nav titles.
3. The row shows the catalogue type and size where matched.

### Phase 3 — Add to inventory
1. `hangar_pledge_items.inventory_item_id` (nullable FK to the deposit it became), so an item remembers where it went; nullified if that entry is deleted.
2. `POST /api/v1/hangar/inventories/:slug/items/bulk`: takes pledge item ids, writes one deposit each in one transaction, links each pledge item to its deposit, skips items already added and says which.
3. `Logistics/InventoryItemModal` accepts a preselected item (name, category, item type and id, quantity), so a row can open it already filled in; the user picks the inventory. Saving from a pledge item links it the same way.
4. A row action "Add to inventory" on ship components and FPS gear; an added row shows its inventory instead.
5. Bulk selection on both lists (`useBulkSelection` + `BulkSelectionBar`) with "Add to inventory".

### Phase 4 — Sync modal
1. The read list counts modules and ship components as separate kinds; the result list adds "Ship components".
2. The last-read summary (`Imports::HangarSync#read_summary`) splits the two the same way, so the comparison per kind holds.

## Intent Verification

- [ ] **A sync of a hangar with coolers and weapons stores them** — they appear in the Ship components list, not dropped, and the import's output names them.
- [ ] **Matched items carry their catalogue type** — a Sovereign IP-10 shows as a power plant.
- [ ] **Switching the setting off leaves stored ship components alone** — as the other kinds do.
- [ ] **Add one** — the row action opens the inventory modal filled in; saving adds a deposit referencing the catalogue item, and the row then names its inventory.
- [ ] **Add many** — selecting items and choosing "Add to inventory" adds one deposit each, in one request, skipping items already added.
- [ ] **FPS gear** — the same two actions work on the FPS gear list, with the equipment catalogue link.
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

- **2026-10-18** Decided with the user: added items are remembered and skipped; FPS gear is in scope (see the issue's Decisions).
- **2026-10-18** Initial research and plan. On a real hangar, 22 of 27 RSI "component" items were ship parts the sync dropped; a quick name probe found most in the component catalogue.

## Progress

- [ ] Phase 1 — Store ship components
- [ ] Phase 2 — List them
- [ ] Phase 3 — Add to inventory
- [ ] Phase 4 — Sync modal
