# Fleet inventory holders

Issue: #6448 (goal, decisions, acceptance live there).

## Phases

1. **Backend: holder on entries** — `holder_id` on `fleet_inventory_items`, holder must be an accepted member (on change), per-holder withdrawal check (lot check included), deposit default (member, else caller), item payload + schema, restorer + activity feed.
2. **Backend: breakdown + filter** — per-holder balances on the stock index rows (per lot) and the stock detail (per position); `heldByMe` on the stock index.
3. **Backend: hand over** — `POST …/stock/:slug/handover`, paired withdrawal + deposit, no notification.
4. **Backend: transfers** — `sourceHolderId` on transfer create (fleet sources), dispatch withdraws from that holder, return-to-source restores it, delivery lands Unassigned.
5. **Frontend** — holder select in the entry modal (deposit default = me; withdrawal lists holders of the lot with balances), breakdown in the stock table, hand-over modal, "held by me" toggle, source holder in the transfer modal, holder column in the ledger, every locale.

## Key files

- `app/models/concerns/inventory_ledger_entry.rb` — withdrawal checks
- `app/models/concerns/inventory_stock.rb` — `current_stock`
- `app/models/fleet_inventory_item.rb`, `app/models/fleet_inventory.rb`
- `app/controllers/api/v1/fleet_inventory_items_controller.rb`, `fleet_inventory_stock_controller.rb`, `concerns/inventory_scoped/stock_actions.rb`
- `app/services/inventories/transfer_{builder,executor}.rb`
- `app/frontend/frontend/components/Fleets/Logistics/InventoryItemModal/index.vue`, `pages/fleets/[slug]/logistics/inventories/[inventory].vue`

## Progress

- [x] 1
- [x] 2
- [x] 3
- [x] 4
- [x] 5

## Not in scope (deferred)

- Holder breakdown on the fleet-wide all-inventories stock view.
