# Personal contracts that deliver into a member's Personal Inventory

Working plan for #5963. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Any fleet member can post a contract that delivers into their own Personal Inventory, the board tells personal and fleet contracts apart, and a fleet can switch personal contracts off.

## Open questions
- None.

## What changed

### Phase 1 — Personal Inventory
1. Migration: `inventories.personal boolean default false null false` + partial unique index on `(holder_type, holder_id) WHERE personal`.
2. `Inventory`: `personal` scope; validations refusing a name change and a `before_destroy` refusal when `personal?` (copy the `throw(:abort)` pattern in `InventoryStock`, skipped when `destroyed_by_association` so account deletion still works).
3. `User`: `after_create :create_personal_inventory` (precedent: `create_default_notification_preferences`), and `User#personal_inventory` that find-or-creates (adopting a same-named hand-made one), race-safe like `Inventory.create_for`.
4. Adopt a hand-made inventory already named "Personal Inventory" (or slugged `personal-inventory`) rather than creating a second one.
5. Call the find-or-create where the user's inventories are listed (`HangarInventoriesController#index`) and in `DestinationOptions#hangar_inventories`.
6. Name: stored as "Personal Inventory"; the frontend shows a translated label for `personal` rows. New key that does not clash with the existing `model.personalInventory` ship metric.
7. Serializer: add `personal` to `shared/_inventory.jbuilder`, bump the cache key in `_hangar_inventory.jbuilder`, update `schemas/hangar/logistics/hangar_inventory.rb`.
8. Frontend: hide the edit button for personal inventories (`InventoryPanel`, `pages/hangar/inventories/[inventory].vue`); list it first.

### Phase 2 — Who may post a personal contract
1. Migration: `fleets.personal_contracts_enabled boolean default true null false`; expose and edit it with the other fleet settings.
2. Personal destinations stay behind `hangar_inventories` via `DestinationOptions`/`TransferGate`; the frontend only offers creating a personal contract while that flag is on.
3. `FleetContractPolicy`: `create?` allows a reader when the fleet allows personal contracts; the fleet-vs-personal destination check stays in `DestinationOptions` (a reader gets no fleet inventories). `show?`, `update?`, `publish?`, `cancel?`, `choose_destination?` let the author handle their own personal contract, drafts included.
4. `FleetContract`: `personal?` (alias of `hangar_destination?`), `personal`/`fleet_owned` scopes; validation refusing a new personal contract when the fleet has switched them off.
5. `visible_scope` in `FleetContractsController`: the author sees their own drafts.
6. Payout: `PayoutLedgerPolicy#manage?` already accepts the contract author — verify with a test, no change expected.

### Phase 3 — API and board
1. `personal` on `fleet_contracts/_base.jbuilder` + response schema.
2. Index filter (`personal=true|false` or a ransack scope) + `fleet_contract_query.rb` schema; regenerate `swagger/v1/schema.yaml` and the fyApi client.
3. Frontend:
   - `contracts/index.vue` `canCreate` and the `new/` route access also open for readers when the fleet allows personal contracts.
   - `ContractForm` destination select: two labelled groups, "Personal" and "Fleet", so it's clear which inventory is whose.
   - Board: a fleet / personal filter and a badge on personal contract cards.
   - Fleet settings: the toggle.
4. Locales in all 7 languages, by hand.

## Intent Verification

- [ ] **Every user has exactly one Personal Inventory**: a new signup has one; an existing user gets one on first read; rename and delete return 400.
- [ ] **A plain member posts a personal contract**: with only `fleet:contracts:read`, create, see, edit and publish a draft delivering into their Personal Inventory; a fleet inventory as destination is refused.
- [ ] **Fleet setting**: switched off, a member's create is refused and existing personal contracts remain.
- [ ] **Select clarity**: the destination select shows personal and fleet inventories in separate labelled groups.
- [ ] **Filter**: the board filters to personal-only and fleet-only.
- [ ] **Payout**: the author manages the payout ledger of their personal contract.

## Key files

| File | Role |
|------|------|
| `app/models/inventory.rb`, `app/models/concerns/inventory_stock.rb` | personal flag, rename/delete guards |
| `app/models/user.rb` | create on signup, find-or-create |
| `app/controllers/api/v1/hangar_inventories_controller.rb`, `app/policies/hangar_inventory_policy.rb` | inventory API |
| `app/models/fleet_contract.rb`, `app/policies/fleet_contract_policy.rb` | personal?, scopes, who may create/edit |
| `app/lib/contracts/destination_options.rb` | which destinations an editor may pick |
| `app/controllers/api/v1/fleet_contracts_controller.rb` | index filter, `visible_scope` |
| `app/views/api/v1/fleet_contracts/_base.jbuilder`, `app/api_components/v1/schemas/contracts/fleet_contract.rb`, `.../queries/fleet_contract_query.rb` | API shape |
| `app/frontend/frontend/components/Fleets/Contracts/ContractForm/index.vue` | grouped destination select |
| `app/frontend/frontend/components/Fleets/Contracts/ContractBoard/` | filter, badge |
| `app/frontend/frontend/pages/fleets/[slug]/contracts/{index.vue,routes.ts}` | create access |

## Not in scope (deferred)
- **Personal contracts for friends** — needs contracts without a fleet (`fleet_id` nullable) and a visibility model outside fleets. Becomes its own issue before the PR merges.

## Discovery Log

- **2026-10-25** Initial research. Hangar destinations exist since #5195; payout author access exists already; readers cannot see their own drafts today; personal destinations depend on `hangar_inventories`.
- **2026-10-25** No `after_create` on User: the inventory is find-or-created where inventories are read (list, destination options), which covers signup and keeps a row out of every user the suite creates.
- **2026-10-25** The payout ledger identified its payer by `fleet_id`; a personal contract is paid by its author, so `payout_participants.payer` replaces that (backfilled for fleet payers).
- **2026-10-25** `FleetMembership#capabilities[:create_contracts]` mirrors `FleetContractPolicy#create?`, so it follows the fleet setting too.
- **2026-10-25** User asks during the work: readonly inputs styled (dimmed caps, no focus highlight), the destination select groups personal and fleet (new opt-in `category` grouping in BaseSelect), and the personal inventory gets its own art slot -- the picture itself is still to be supplied.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Personal inventory art (`app/frontend/images/inventories/personal/`)
