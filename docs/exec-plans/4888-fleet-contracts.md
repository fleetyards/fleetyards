# Fleet contracts — jobs for members, tracked through the transfer ledger

## Goal

A fleet posts contracts its members claim, work and get paid for — haul goods between two fleet
inventories, buy goods and bring them in, or craft items at a required quality — where progress is
read out of the transfer ledger rather than typed in, and a fulfilled contract carries an agreed
reward and a per-contractor delivered share for the payout that settles it.

## Context

#4878 / #4881 gave stock a way to move between two inventories as one recorded event. That is the
piece this needs and the piece that was missing: before it, a member handing cargo to their fleet was
two unrelated ledger rows, so nothing above the ledger could tell that a delivery had happened.

A transfer's deposits at the destination are written **only** on acceptance — a declined, cancelled
or expired transfer compensates back into the *source* (#4878 D2). So "what has been delivered" is
already an exact, append-only quantity sitting in `fleet_inventory_items`, and a contract does not
need a progress column. It needs a foreign key and a query.

The money side has no ledger of its own to invent, either. There is no wallet, balance or currency
anywhere in the app — `aUEC` exists only as a formatted number on `Model` — but #2640 built one:
`payout_ledgers` / `payout_participants` / `payout_entries` / `payout_transfers`, with
`Payouts::Settlement` computing balances and a greedy min-cash-flow transfer list, on #4882. That is
the payment machinery a contract wants, and it is three small extensions away from fitting (D5).

Resolves #4888 · stacks on `feat/4878-inventory-transfers` (#4881)

## Decisions

### D1 — Progress is a query over the transfer ledger, never a column

`inventory_transfers` gains one nullable `fleet_contract_id`. Delivered quantity for a contract line
is then:

```
Σ quantity  of fleet_inventory_items
  WHERE entry_type = deposit
    AND fleet_inventory_id = the contract's destination
    AND inventory_transfer_id IN (the contract's transfers)
    AND (lower(name), category, unit) = the line's identity
    AND (quality >= line.min_quality)          -- crafting only
```

No `delivered_quantity` to drift, and the same reasoning `StockPosition` and #4855 D2 give for not
storing stock. It also means a contract cannot be advanced by pressing a button: a member who has not
moved the goods has nothing to count.

**Attribution is the sending party, not the initiator.** `InventoryTransfer.party_of(source)` on a
delivery is the contractor whose inventory the goods left, which is right even when an officer pressed
the button on their behalf. `initiated_by` is the fallback for the case where the source row was
nulled by an account deletion.

Rejected: a `fleet_contract_deliveries` join table snapshotting each delivery. It is the stored
aggregate again, and it would disagree with the ledger the first time a transfer was resolved outside
the contract path.

### D2 — Matching a delivery to a line is the ledger's own identity rule

A line carries `name`, `category`, `unit` and matches deposits on `(lower(name), category, unit)` —
the same triple `InventoryLedgerEntry::POSITION_COLUMNS` uses to decide that two entries are the same
stock position. A line may *also* carry an `item_type`/`item_id` reference (the `ITEM_TYPES`
allowlist, unchanged), but only for the icon and the link: the reference is optional on entries, so
matching on it would silently fail to count a hand-typed deposit of the right goods.

Rejected: matching on the item reference when present and falling back to the name otherwise. Two
rules means a contract counts differently depending on how the contractor happened to enter their
stock.

### D3 — Transport is two fleet inventories, and pickup is tracked separately from delivery

A transport contract names a source and a destination fleet inventory. It generates two legs, both
ordinary transfers linked to the contract:

| leg | transfer | what it writes | counted as |
|---|---|---|---|
| pickup | source fleet inventory → the contractor's own inventory | withdrawals at the source | `pickedUp` |
| delivery | the contractor's inventory → destination fleet inventory | deposits at the destination | `delivered` |

`delivered` is what fulfils the contract; `pickedUp` is shown beside it so a half-finished haul reads
as *in the contractor's hold* rather than as lost. Procurement and crafting have no pickup leg — the
goods come from outside the app — so only `delivered` applies.

This grants nobody anything: the pickup is the fleet → member movement #4878 already authorises, and
the delivery is the member → fleet one.

### D4 — A lead claims; crew join with the lead's consent

One `fleet_contract_assignments` row per person, `role` ∈ `lead | crew`, with its own small state
machine (`requested → accepted`, plus `declined`, `withdrawn`, `removed`).

- Claiming an `open` contract creates the **lead** row directly in `accepted` and moves the contract
  to `in_progress`. A partial unique index enforces one accepted lead per contract.
- Anybody else with read access creates a `crew` row in `requested`. The **lead** accepts or declines
  it; a member with `fleet:contracts:manage` may do so too, and may also remove someone — an officer
  has to be able to unstick a contract whose lead has gone quiet.
- The lead releasing the contract returns it to `open` and withdraws the whole crew. Their delivered
  quantities stay in the ledger and still count, and will still be paid: the goods are in the fleet's
  inventory either way, and taking the payment away because someone left would be theft.

Rejected: an open board with no claiming. It cannot express "this is mine, don't duplicate it", which
is the thing a contract is for. Rejected: officers assigning work top-down as the only path — the
issue describes members picking jobs up.

### D5 — The payment settles on #2640's ledger, in a follow-up

#4882 built `payout_ledgers` / `payout_participants` / `payout_entries` / `payout_transfers` and
`Payouts::Settlement`, on `main`. A contract payment is a `payout_transfer` — from → to → amount with
`confirm!` — and building a second money table beside that one would leave the app with two.

It is not merged yet, and it is currently `CONFLICTING`, so this change does not stack on it as well.
Contracts, crew and delivered progress land here with the reward **recorded** on the contract; the
settlement lands as its own change once #4882 is on main. Three extensions, all small, specified here
so the follow-up is mechanical rather than a re-design:

1. **A participant may be a fleet.** `payout_participants` gains a nullable `fleet_id` beside
   `user_id` and `name`, exactly one of the three set. A contract's payer is the fleet, and without
   this the fleet would have to be a free-text guest — which cannot be authorised, notified or linked.
   It is the same two-nullable-columns-for-one-party shape `InventoryTransfer` uses for `recipient` /
   `recipient_fleet`, for the same reason.
2. **`FleetContract` joins `PayoutLedger::SUBJECT_TYPES`**, and `PayoutLedgerPolicy` gains the branch
   for it — delegating to `FleetContractPolicy`, as it already branches between the event and the tour.
3. **Settlement becomes a strategy.** `Payouts::Settlement` already owns everything that is common —
   minor units, largest-remainder rounding, the greedy min-cash-flow pass and the `Σ net == 0`
   invariant — and only its `share` rule is tour-specific. It splits into a base plus `EqualShares`
   (what it does today, unchanged behaviour) and `ContractPayout` (D6).

Rejected: merging #4882's branch into this one to ship the whole feature at once. It gives a diamond
base whose diff carries both stacks, `api-schema-breaking` effectively diffs against main either way,
and a force-push on either parent cascades into this. Rejected: a `fleet_contract_payments` table of
its own — smaller today, and a second money table to converge later. Rejected: making aUEC a
`currency` category in the inventory ledger so a payment is literally a transfer; it reuses even more
machinery, but it turns every inventory into a treasury and changes what `stock_volume`, the SCU
rollups and the CSV importer mean.

**What lands here** is everything the payout needs to be computable: `reward decimal(15, 2)`,
`reimburse_expenses`, and `Contracts::Progress` reporting delivered quantity **per contractor**. The
follow-up reads those and writes transfers; it adds no new measurement.

### D6 — The reward splits by fraction-of-line-delivered, not by quantity

Specified here because `Contracts::Progress` has to produce the number it consumes; applied by the
follow-up.

Quantities do not add up across units — a contract can ask for 800 SCU of titanium and 12 power plants,
and "how much did you deliver" has no single number. So each line contributes a ratio:

```
w_c = Σ over lines ( delivered_by_c on line / line.quantity )
share_c = reward × w_c / Σ w
```

Unit-free, exactly the delivered fraction when there is one line, and it weights a line by how much of
it was asked for rather than by which unit it happens to use.

Expenses are settled first and in full, which is what `Payouts::Settlement` already does and what makes
a procurement contract work: the contractor fronts the purchase and is made whole before any reward is
divided.

### D7 — Fulfilment is automatic, and an officer can force it

When a transfer linked to a contract completes, the contract re-reads its progress; if every line is
met it moves `in_progress → fulfilled` and notifies the fleet. A member with `fleet:contracts:manage`
can also fulfil early — partial deliveries, a renegotiated job — because the alternative is a contract
that can never be paid.

`fulfilled` is terminal in this change. `settled` is added by the follow-up, as the separate deliberate
step #2640 D5 argues for: settling freezes the ledger, because once people start paying against the
list it has to stop moving.

### D8 — Its own flag, riding the two below it

`fleet_contracts` in `config/feature_flags.yml`. A contract is measured through transfers into fleet
inventories, so it composes with `fleet_logistics` and `inventory_transfers` rather than replacing them
— the reasoning `InventoryTransfersFeatureConcern` gives, unchanged.

### D9 — Its own privilege group

`FleetContract::AVAILABLE_PRIVILEGES` = `fleet:contracts:{read,create,update,delete,manage}`, registered
as `"contracts"` in `FleetRole::PRIVILEGE_GROUPS`; officers get `manage`, members `read`. Claiming and
crewing need only `read` — a contract nobody but an officer could take is not a job board.

No `fleet:payouts:*` is touched here: #4882 defines that group, and the contract ledger's authorization
is the D5 follow-up's branch.

## What changed

### Phase 1 — Schema

Four migrations, all `id: :uuid, default: -> { "gen_random_uuid()" }`, every model annotated.

1. `fleet_contracts` — `fleet_id`, `created_by_id`, `title`, `slug`, `description`, `kind`
   (`transport: 0`, `procurement: 1`, `crafting: 2`), `source_fleet_inventory_id`,
   `destination_fleet_inventory_id`, `reward decimal(15,2)`, `reimburse_expenses`, `crew_limit`,
   `deadline`, `aasm_state`, and the state timestamps. Unique on `[fleet_id, slug]`; index on
   `[fleet_id, aasm_state]`. Both inventory keys `ON DELETE SET NULL` — the reasoning #4878 D4 was
   corrected to, unchanged: a fleet must stay able to delete an inventory a finished contract names.
2. `fleet_contract_items` — `fleet_contract_id`, `name`, `category`, `unit`, `item_type`, `item_id`,
   `quantity decimal`, `min_quality`, `position` for ordering.
3. `fleet_contract_assignments` — `fleet_contract_id`, `user_id`, `role`, `aasm_state`, the state
   timestamps, `approved_by_id`. Unique on `[fleet_contract_id, user_id]`, plus a partial unique index
   on `fleet_contract_id WHERE role = 0 AND aasm_state = 'accepted'`.
4. `add_fleet_contract_to_inventory_transfers` — one nullable `fleet_contract_id`, `ON DELETE SET NULL`,
   indexed.

Quantities and amounts are always positive; direction is carried by the type column, as
`InventoryLedgerEntry` carries deposit/withdrawal.

### Phase 2 — Models

1. `FleetContract` — AASM (`timestamps: true`, `whiny_transitions: false` to match the house style):
   `draft → open → in_progress → fulfilled`, plus `cancel` from anywhere before `fulfilled` and
   `expire` from `open`/`in_progress`. Slug via `generate_slug(title)` prefixed with the first id
   segment, the `FleetEvent#update_slug` shape. Validations: a destination inventory belonging to the
   same fleet; a source inventory too, and only, when `transport?`; at least one item before `publish`;
   `min_quality` only meaningful when `crafting?`.
2. `FleetContractItem` — the `InventoryLedgerEntry` enums (`category`, `unit`) and its
   `UNITS_BY_CATEGORY` pairing, `quantity > 0`, `min_quality` 0..1000, the `ITEM_TYPES` inclusion and
   the `referenced_item_exists` check, lifted rather than re-typed.
3. `FleetContractAssignment` — AASM, an `accepted_lead` scope, and a validation that a contract at its
   `crew_limit` takes no more accepted crew.
4. `InventoryTransfer` — `belongs_to :fleet_contract, optional: true`, and an `after_commit` on
   completion that asks the contract to re-check itself (D7).

### Phase 3 — Progress

1. `app/lib/contracts/progress.rb` — one grouped query per contract over `fleet_inventory_items`,
   keyed by position identity and by sending party, returning per line: `requested`, `delivered`,
   `pickedUp`, `remaining`, `complete?`, and a per-contractor breakdown carrying the D6 weight. One
   query, not N per line.
2. `app/lib/contracts/fulfilment.rb` — the D7 check, run inside the transfer's completion, locking the
   contract and re-reading before it transitions. `whiny_transitions: false` hides a losing transition
   that has already written, so the re-read happens inside the transaction.

### Phase 4 — Permissions, flag, notifications

1. `config/feature_flags.yml` gains `fleet_contracts`; `bin/feature-flags validate` then `sync`. The
   flag has to be in the YAML **before** `bin/generate-schema`, or `FeatureFlagName.FLEET_CONTRACTS`
   will not exist in TypeScript.
2. `FleetRole::PRIVILEGE_GROUPS` gains `"contracts"`, and `preset_privileges` its three entries.
3. `db/data/*_grant_contract_privileges_to_existing_roles.rb`, modelled on the mission one —
   `setup_default_roles!` only runs at fleet creation, so without it every existing fleet gets a 403 on
   a feature that looks switched on.
4. `FleetContractPolicy` and `FleetContractAssignmentPolicy`, both `< FleetBasePolicy`, the child
   delegating through `context: {fleet_contract:}` the way `FleetEventSignupPolicy` does.
5. `Notifications::InApp::FleetContractSubscriber` over `fleet_contract.*` events, the
   `FleetEventSubscriber` shape. Five `Notification` types: `fleet_contract_published`,
   `fleet_contract_claimed`, `fleet_contract_crew_requested`, `fleet_contract_crew_accepted`,
   `fleet_contract_fulfilled`. The notification enum is broadcast over cable, so
   `asyncapi/cable/v1/schema.yaml` restages with it or `api-schema-check` goes red, and `oasdiff`
   ignore entries are needed for the enum widening, matching the existing `cosmetic` ones.

### Phase 5 — API

Routes in a new `config/routes/api/contracts_routes.rb`, drawn from `fleets_routes.rb`:

```
resources :fleet_contracts, path: "contracts", param: :slug, only: %i[index show create update destroy] do
  member do
    put :publish ; put :claim ; put :release ; put :fulfil ; put :cancel
    get :progress
  end
  resources :fleet_contract_items,       path: "items", only: %i[create update destroy]
  resources :fleet_contract_assignments, path: "crew",  only: %i[index create destroy] do
    member { put :accept ; put :decline }
  end
end
```

`InventoryTransferActions#transfer_params` gains `:contract_id`, and `TransferBuilder` a `contract:`
keyword that refuses the link unless the actor is an accepted contractor, the contract is
`in_progress`, and the end being written is one the contract actually names. A refused contract link is
a 400, never a silently unlinked transfer.

Controllers follow `missions_controller.rb`: `authorize!` on every action, the doorkeeper scope pairs,
`result_with_pagination` + `pagination_header`, `ValidationError.new("fleet_contracts.create", …)`.
Jbuilder in `app/views/api/v1/fleet_contracts/` and siblings, four files each — `_base`, `_<singular>`
with `json.cache! ["v1", record]`, `index`, `show`. Progress is computed per request and renders
**outside** any cache block.

OpenAPI components under `app/api_components/v1/schemas/contracts/`, enums in `v1/schemas/enums/` and
not `shared/v1/`. Every nested object is its own component — the progress rows and the per-contractor
breakdown included.

### Phase 6 — Frontend

1. `app/frontend/frontend/pages/fleets/[slug]/contracts/routes.ts` mounted from the fleet's `routes.ts`
   as its own section beside logistics: `/contracts/`, `/contracts/add/`, `/contracts/:contract/`,
   `/contracts/:contract/edit/`. Each route carries `feature: FeatureFlagName.FLEET_CONTRACTS`,
   `featureScope: "fleet"`, `access: ["fleet:contracts:read", "fleet:contracts:manage", "fleet:manage"]`,
   and both a `nav.*` and a `title.*` key — a `t(` grep finds neither, so both get written by hand.
2. `components/Contracts/` — `ContractCard`, `ContractBoard`, `ContractForm`, `ContractItemsForm`,
   `ContractProgress` (per-line bars, pickup beside delivery for transport), `ContractCrewList`,
   `ContractDeliverModal` (a thin shell over the existing `TransferModal`, pre-filled with the
   contract's destination and carrying `contractId`).
3. The reward renders through the existing `toUEC`, not a new helper. Data comes from the orval hooks;
   refresh after a mutation via `refetch()` on the `useComlink` bus, as the missions pages do.
4. i18n under `nav.*`, `title.*`, `headlines.*`, `labels.*`, `actions.*`, `messages.*`, `empty.*`, in
   all seven locales by hand — Crowdin is not in use and `enableFallback` hides every gap.

### Phase 7 — Tests

1. `test/models/` — the contract state machine, item validations, and the lead-uniqueness and
   crew-limit indexes asserted as `ActiveRecord::RecordNotUnique`, not only as validations.
2. `test/lib/contracts/progress_test.rb` — the important one. A delivery counted; a *declined* transfer
   counted as nothing; a crafting line ignoring an under-quality deposit and counting an over-quality
   one; a transport contract's pickup and delivery kept apart; a hand-typed deposit with no transfer not
   counting; two contractors attributed separately; a deposit into the wrong inventory ignored; and the
   D6 weights summing to 1 across a fully delivered multi-line contract.
3. `test/lib/contracts/fulfilment_test.rb` — including two real threads completing the last two
   deliveries at once, which is the race `whiny_transitions: false` hides.
4. `test/integration/api/v1/` — one file per endpoint and verb with its own `api_path` block; `setup`
   enables `fleet_contracts`, `fleet_logistics` and `inventory_transfers`. Cross-fleet 404s, the
   crew-approval 403s, and the refused contract link on transfer create.
5. `test/factories/` for each new model; frontend `*.spec.ts` beside `ContractProgress` and
   `ContractCrewList`, unmounting VTU wrappers in teardown.

## Intent Verification

- [ ] **A fleet can post each of the three kinds of job** — transport names two fleet inventories,
      procurement and crafting one, each with goods, quantities, a reward and a deadline, and a crafting
      contract carries a required quality.
- [ ] **Members claim and crew up** — a member claims an open contract and becomes its lead; a second
      member requests to join and the lead or an officer accepts or declines them.
- [ ] **Progress comes from the transfer system** — the bar moves only when a transfer linked to the
      contract deposits the requested goods at the destination inventory, and a declined transfer moves
      nothing.
- [ ] **Quality is enforced** — a crafting contract does not count a deposit below its required quality.
- [ ] **Transport shows both legs** — goods out of the source inventory read as picked up, goods into
      the destination as delivered.
- [ ] **The payout is computable** — a fulfilled contract reports, per contractor, the delivered share
      D6 divides the reward by, and the reward and reimbursement terms it is divided from.

## Key files

| File | Role |
|------|------|
| `db/migrate/*` | The three new tables and the one new column |
| `app/models/fleet_contract.rb` | Lifecycle, the three kinds, the two inventory ends |
| `app/models/fleet_contract_assignment.rb` | Lead and crew, with the approval handshake |
| `app/models/inventory_transfer.rb` | Gains `fleet_contract`, and the completion hook |
| `app/lib/contracts/progress.rb` | The one query the whole feature reads from |
| `app/lib/contracts/fulfilment.rb` | The automatic transition, locked against the race |
| `app/services/inventories/transfer_builder.rb` | Where a transfer earns its contract link |
| `app/models/fleet_role.rb` | `PRIVILEGE_GROUPS` gains `"contracts"` |
| `config/feature_flags.yml` | `fleet_contracts` |
| `db/data/*_grant_contract_privileges_to_existing_roles.rb` | Without it, existing fleets 403 |

## Not in scope (deferred)

- **The payment itself** — D5. Follows once #4882 is on main: `payout_participants.fleet_id`,
  `FleetContract` in `SUBJECT_TYPES`, `Payouts::Settlement` split into a base plus `EqualShares` and
  `ContractPayout`, a `fulfilled → settled` transition, a `fleet_contract_settled` notification, and the
  `Payouts/` components mounted on a contract page.
- **Reward by negotiation** — the lead setting per-crew percentages. The delivered share is derived and
  needs no screen; the assignment row is where a weight would later go.
- **Recurring or templated contracts** — a standing "keep the depot stocked" job. Worth having, needs
  its own scheduling decision.
- **Discord announcement of a new contract** — `Notifications::Discord` has one subscriber today; a
  second is a follow-up.
- **Contract expiry job** — `deadline` is recorded and shown; the sweep that moves a lapsed contract to
  `expired` rides with `Inventories::ExpireTransfersJob` in a follow-up rather than adding a second
  scheduled job here.

## Discovery Log

- **2026-09-13** Initial research and plan creation. Confirmed with the user: transport runs between two
  fleet inventories; a lead claims and approves crew; the reward splits by delivered quantity.
- **2026-09-13** Corrected the base. The plan had assumed #2640 was unbuilt and that its ledger would
  land here; it is in fact built and reviewed on #4882, which is `CONFLICTING` with main. The money side
  became a follow-up on that branch (D5) rather than a second money table or a diamond base.

## Progress

- [ ] Phase 1 — Schema
- [ ] Phase 2 — Models
- [ ] Phase 3 — Progress
- [ ] Phase 4 — Permissions, flag, notifications
- [ ] Phase 5 — API
- [ ] Phase 6 — Frontend
- [ ] Phase 7 — Tests
