# Fold FleetInventoryStockController into InventoryScoped::StockActions

Working plan for #5162. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`Api::V1::FleetInventoryStockController` takes its actions from `InventoryScoped::StockActions`, with fleet authorization unchanged.

## What changed

### Phase 1 — Authorization hooks in the concern
1. `StockActions` authorizes through two overridable private methods, `authorize_stock_read!` and `authorize_stock_write!`, whose defaults keep the hangar/vehicle behaviour (`inventory_policy`, `show?`/`update?` on the inventory).
2. The fleet controller overrides both with the record-less `FleetInventoryItemPolicy` rules it uses today (`index?` for reads; `update?`/`destroy?`, which alias to the same rule, for writes) in the fleet context.

### Phase 2 — Fleet controller on the concern
1. Include `InventoryScoped::StockActions`, drop the hand-written actions, `stock_item_params` and `set_stock_item`.
2. `inventory` returns the inventory found by the eager `set_inventory` before_action, so a missing or hidden inventory still answers 404 before any rule runs.
3. `validation_error_scope` is `fleet_inventory_items`.

## Intent Verification

- [ ] **Concern in use** — fleet stock controller includes `InventoryScoped::StockActions` and defines no actions
- [ ] **Authorization unchanged** — same policy, same rules, same 404-before-403 order
- [ ] **Schema unchanged** — `swagger/` and `asyncapi/` untouched after regeneration
- [ ] **Tests unchanged and green** — `test/integration/api/v1/fleets_inventory_stock_*_test.rb`

## Key files

| File | Role |
|------|------|
| `app/controllers/concerns/inventory_scoped/stock_actions.rb` | Shared stock actions |
| `app/controllers/concerns/inventory_scoped.rb` | Contract the including controller fulfils |
| `app/controllers/api/v1/fleet_inventory_stock_controller.rb` | The duplicate being folded in |
| `app/policies/fleet_inventory_item_policy.rb` | Fleet stock rules |

## Not in scope (deferred)
- **`FleetInventoryItemsController` onto `InventoryScoped::ItemActions`** — same duplication on the ledger-entry side; differs more (member attribution, fleet-specific params).

## Discovery Log

- **2026-10-08** Fleet stock authorizes record-less against `FleetInventoryItemPolicy` with a fleet context, while the concern authorizes the inventory record against `inventory_policy`. `FleetInventoryPolicy` uses different privilege lists, so swapping policies would change who may act — hence hooks rather than a policy swap.

## Progress
- [ ] Phase 1
- [ ] Phase 2
