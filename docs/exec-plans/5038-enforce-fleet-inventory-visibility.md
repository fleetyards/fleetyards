# Fleet inventory visibility (officers_only) is never enforced

## Goal

An `officers_only` fleet inventory — its name, its entries and its rolled-up stock — is reachable only by members whose role carries manage-level inventory access, across every endpoint that serves fleet inventory data.

## Context

`FleetInventory#visibility` has existed as a column, an enum, a rendered field and a user-supplied ransack filter without a single rule enforcing it. Every fleet inventory read authorizes on the fleet and the member's privileges; the inventory record is never handed to the policy, so visibility cannot be consulted even in principle.

Found while scoping live inventory updates (#5039), which is blocked on this: a per-user cable fan-out has to know who may see an inventory, and building it against an unenforced rule would either bake the gap into the broadcast audience or make the cable stricter than the endpoint it keeps in sync.

Resolves #5038

## Decisions

### D1 — "Officer" is manage-level inventory access

No officer privilege exists in `FleetRoleResourceAccessEnum`. The nearest established rule is the recipient filter in `FleetInventoryItem#notify_inventory_entry`, which treats `fleet:manage` / `fleet:inventories:manage` as the elevated set.

- `officers_only` → `fleet:manage`, `fleet:inventories:manage`, plus the inventory's own `managed_by` manager
- `members_only` → unchanged (`fleet:inventories:read` and above)

The manager is included because `FleetInventory#managed_by` names the person answerable for that inventory; excluding them from their own officers-only store would be perverse. Rejected: a new `fleet:inventories:officer` privilege — it would ship as "translation missing" in seven locales and needs a data migration to grant, for a distinction the manage set already draws.

### D2 — One authorized scope, applied at the two chokepoints

The rule goes in a `relation_scope` on `FleetInventoryPolicy`, following `HangarInventoryPolicy`. It reaches the six endpoints through exactly two call sites per controller:

- `set_fleet_inventory` — `@fleet.fleet_inventories.find_by!(slug:)` becomes a lookup through the authorized scope. Covers show, update, destroy, and both per-inventory stock and items controllers.
- the aggregate reads — `@fleet.fleet_inventories.pluck(:id)` in `FleetAllInventoryStockController` and the `fleet_inventories` join in `FleetAllInventoryItemsController`.

A new endpoint that reaches for `@fleet.fleet_inventories` directly still bypasses it; that is what the policy test is for.

### D3 — Not found, not forbidden

Routing the per-inventory lookup through the scope makes `find_by!` raise, so a non-officer gets 404. That is deliberate: 403 on a slug confirms the inventory exists, which is most of what officers-only is hiding.

### D4 — Narrow the aggregates, don't refuse them

All-stock and all-items answer across inventories. For a non-officer they drop officers-only rows and return the rest — a member with read access still has a legitimate answer coming. Refusing the whole request would break the blueprint detail page and the logistics overview for every member of a fleet that keeps one officers-only store.

### D5 — Writes are gated by the same rule

Visibility gates the record, not the verb. A member holding `fleet:inventories:update` but not the manage set cannot deposit into, correct or empty an officers-only inventory — which falls out of D2, since the write controllers reach their record through the same `set_fleet_inventory`.

### D6 — `visibility_eq` may only narrow

`FleetInventoriesController#index` permits `visibility_eq` as a user-supplied filter. Ransack runs on top of the authorized scope, so it can only narrow what the scope already allows. Verified by test rather than by reading, because the ordering of `authorized_scope` and `.ransack` is what makes it true.

## What changed

### Phase 1 — The rule

1. `relation_scope` on `FleetInventoryPolicy`: all inventories for a member with the manage set; otherwise `members_only` plus any inventory where `managed_by` is the user.
2. Record-level `show?` consults visibility instead of aliasing to the record-blind `index?`.
3. `FleetMembership::CAPABILITY_PRIVILEGES` — checked, and left alone. The client gates lists on what the endpoints return, and the scope now returns less; a capability boolean would be an unused API field.

### Phase 2 — The call sites

4. `FleetInventoriesController#set_fleet_inventory` and `#index` scope.
5. `FleetInventoryStockController#set_fleet_inventory`.
6. `FleetInventoryItemsController#set_fleet_inventory`.
7. `FleetAllInventoryStockController#index` — the `pluck(:id)`.
8. `FleetAllInventoryItemsController#index` — the join.
9. `Inventories::TransferAuthorizer` — `may_withdraw_from?` / `may_deposit_into?` now ask `visible_to?` as well, so an officers-only store is not an end a plain writer can name. `TransferBuilder` calls both, so this reaches transfer creation.
10. `InventoryTransferActions#incoming_scope` / `#outgoing_scope` — the seventh surface, found late: a transfer names the inventory it moved through, so the fleet's transfer list told a member with write access the name of every officers-only store.

### Phase 3 — Coverage

11. Extend the existing per-endpoint integration tests (`fleets_inventories_index_test.rb`, `_show_`, `fleets_all_inventory_stock_index_test.rb`, `fleets_all_inventory_items_index_test.rb`, `fleets_inventory_stock_index_test.rb`, `fleets_inventory_items_index_test.rb`) with an officers-only inventory read by a read-only member, a manage-level member, and the named manager.
12. A policy test for the relation scope, so a future endpoint that bypasses it is the only way to regress.

## Intent Verification

- [ ] An `officers_only` inventory is invisible to a member holding only `fleet:inventories:read`, across all six read endpoints
- [ ] The same member sees `members_only` inventories exactly as before
- [ ] All-stock and all-items drop officers-only rows rather than 403-ing the request
- [ ] The inventory's `managed_by` manager reaches their own officers-only inventory regardless of privilege set
- [ ] A non-officer gets 404, not 403, on an officers-only slug
- [ ] A non-officer cannot write to an officers-only inventory
- [ ] `visibility_eq` cannot widen the authorized scope
- [ ] Blueprint detail held-stock rows exclude officers-only stock for non-officers
- [ ] The fleet's transfer list does not name an officers-only inventory to a plain writer

## Key files

| File | Role |
|------|------|
| `app/policies/fleet_inventory_policy.rb` | Where the rule lands; `show?` currently aliases to a record-blind `index?` |
| `app/policies/fleet_base_policy.rb` | Supplies `accepted_fleet_membership` from the fleet context |
| `app/policies/hangar_inventory_policy.rb` | The `relation_scope` precedent |
| `app/controllers/api/v1/fleet_inventories_controller.rb` | `set_fleet_inventory`, and the `visibility_eq` ransack filter |
| `app/controllers/api/v1/fleet_all_inventory_stock_controller.rb` | `@fleet.fleet_inventories.pluck(:id)`, read by the blueprint page |
| `app/controllers/api/v1/fleet_all_inventory_items_controller.rb` | The unfiltered `fleet_inventories` join |
| `app/controllers/api/v1/fleet_inventory_stock_controller.rb` | Per-inventory stock, same lookup |
| `app/controllers/api/v1/fleet_inventory_items_controller.rb` | Per-inventory entries, same lookup |
| `app/models/fleet_membership.rb` | `has_access?` and `CAPABILITY_PRIVILEGES` |
| `app/models/fleet_inventory.rb` | The `visibility` enum, `managed_by`, and `visible_to?` — the one definition of the rule |
| `app/controllers/concerns/fleet_inventory_scoped.rb` | `visible_fleet_inventories`, the single grep target for every scoped read |
| `app/services/inventories/transfer_authorizer.rb` | The two ends of a transfer |
| `app/controllers/concerns/inventory_transfer_actions.rb` | The transfer list scopes |

## Not in scope (deferred)

- **The cable broadcasts (#5039)** — blocked on this, deliberately kept separate
- **A dedicated officer privilege** — see D1
- **Admin endpoints** (`Admin::Api::V1::FleetInventories*`) — staff already read every fleet's data by design
- **Whether `members_only` should exclude non-members entirely** — it already does; membership is checked before any of this

## Discovery Log

- **2026-09-19** Initial research and plan creation. Confirmed no controller, scope or policy consults `visibility`; the only references are the enum, the jbuilder field, the permitted ransack key and the params filter. Confirmed the six read endpoints and the two chokepoints. Confirmed thorough per-endpoint integration coverage already exists to extend.
- **2026-09-19** D1 confirmed by the code rather than by argument: `FleetInventory::DEFAULT_PRIVILEGES` already seeds the officer role with `fleet:inventories:manage` and the member role with `fleet:inventories:read`, which is exactly the line drawn here.
- **2026-09-19** The rule ended up on the model as `FleetInventory#visible_to?` rather than in the policy, because `Inventories::TransferAuthorizer` needs the same answer and reaches no policy. The policy's relation scope is the SQL half of it; `FleetInventoryPolicyTest` asserts the two agree over the same set for every reader.
- **2026-09-19** A seventh surface, not in the original six: `InventoryTransferActions` scopes the fleet's transfer list over `acting_party.fleet_inventories`, so a member with `fleet:inventories:update` could read the name of any officers-only store the fleet moved stock through. Scoped alongside the rest.
- **2026-09-19** `fleet:logistics:manage` in `FleetInventoryItem#notify_inventory_entry` is not in `FleetRoleResourceAccessEnum` — a privilege that can never match. Left alone: it grants nothing, and it is not this change's business.
- **2026-09-19** No OpenAPI schema change: `swagger/` is untouched. The two endpoints whose refusal is asserted with a raw `get` (`inventory_stock_index`, `inventory_items_index`) declare no 404 response in their DSL block, and declaring one is a documentation change of its own.
- **2026-09-19** Review found two things the scoping missed. A transfer addressed to a fleet keeps `recipient_fleet` through `accept`, so the `recipient_fleet` branch listed one accepted into a hidden store whatever its destination scope said — and the same leak exists on the source side. `with_visible_fleet_ends` now guards both ends of both scopes, excluding only *this* fleet's hidden inventories so a cross-party far end still lists, and spelling the condition out rather than using `where.not`, which would drop every transfer with one end still unset.
- **2026-09-19** The relation scope skipped the read gate `show?` applies, so the two halves disagreed for a member whose role carries no inventory access. Both apply `READ_PRIVILEGES` first now. The manager exception lifts the officers-only bar, not the baseline read privilege — the comment claiming otherwise was the actual defect.

## Progress

- [x] Phase 1 — The rule
- [x] Phase 2 — The call sites
- [x] Phase 3 — Coverage
