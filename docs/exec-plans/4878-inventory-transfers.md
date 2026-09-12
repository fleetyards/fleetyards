# Transfer items from one inventory to another

## Goal

Stock moves between any two inventories as one recorded event, in one transaction, with several positions at a time — between a user's own inventories, within a fleet, and across parties in either direction, where it waits for the receiving side to accept it and say where it lands.

## Context

Every write path in this subsystem touches exactly one inventory. `InventoryScoped` (`app/controllers/concerns/inventory_scoped.rb:14`) is built around a single `#inventory`, `InventoryStock` rolls up a single ledger, and `withdrawal_does_not_exceed_stock` (`inventory_ledger_entry.rb:310`) locks a single inventory row. Nothing in the app has ever written to two.

So unloading a ship into a hangar locker is done by hand, twice: a withdrawal on one page and a deposit on another, with the three position labels retyped. The two entries are unrelated rows. A typo does not fail — `assign_position` (`inventory_ledger_entry.rb:249`) find-or-creates, so a mistyped name silently opens a second position at the destination while the source shows the goods gone.

Six movements are wanted, across two holder kinds:

| from | to |
|---|---|
| a user's inventory | another inventory of the same user |
| a fleet's inventory | another inventory of the same fleet |
| a user's inventory | another user's inventory |
| a fleet's inventory | another fleet's inventory |
| a user's inventory | a fleet's inventory |
| a fleet's inventory | a user's inventory |

The last two are what makes this more than a convenience: they cross the two parallel schemas, `inventory_items` and `fleet_inventory_items`, which nothing in the app has ever done.

Resolves #4878

## Decisions

### D1 — All six movements, and a transfer may cross the two schemas

The subsystem is two parallel stacks — `inventories`/`fleet_inventories`, `inventory_items`/`fleet_inventory_items`, `inventory_positions`/`fleet_inventory_positions` — each pair sharing a concern (`InventoryStock`, `InventoryLedgerEntry`, `StockPosition`). Every existing write stays on one side. A user↔fleet transfer does not, and that single fact drives D4, D5 and D6.

It is less frightening than it sounds, because the two ledger tables are not two shapes. Measured against the schema:

```
fleet_inventory_items  =  inventory_items  +  added_by  +  member_id
```

Fourteen columns in common, in the same types, with the same enums, validations and callbacks — all of them in `InventoryLedgerEntry`. The two extra columns are provenance, not content, and the hook that supplies them **already exists**: `InventoryStock#ledger_attributes_for(user)` (`inventory_stock.rb:33`) returns `{}` on `Inventory` and `{added_by: user&.id}` on `FleetInventory` (`fleet_inventory.rb:72`). It was written for the CSV importer. It is exactly what a cross-schema deposit needs, and it means the copy step is one merge rather than a mapping table.

So the rule is: a transfer names a **source position** and a **destination inventory**, and the destination's own class decides what a deposit into it looks like.

### D2 — Stock leaves on send. A pending transfer is escrow

The one decision the whole design turns on. `withdrawal_does_not_exceed_stock` checks against the live rollup at write time, which means a transfer that only withdraws when the recipient accepts can **fail at acceptance** — the sender spent the goods in between, and the recipient is told no after saying yes.

There is no way to reserve stock without withdrawing it, because stock is not stored. It is `SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END)` over the entries (`inventory_stock.rb:37`), so the only thing that reduces it is a withdrawal row. A `reserved_quantity` column beside it would be the stored aggregate that #4855 D2 explicitly refused, and it would have to be subtracted at every one of the six read sites.

So the withdrawal happens on send, and the goods are in transit:

| event | what is written |
|---|---|
| `send` | one withdrawal per line, on the **source** inventory |
| `accept` | one deposit per line, on the **destination** |
| `decline` / `cancel` / `expire` | one deposit per line, back into the **source** |

Nothing is ever deleted or edited to undo a transfer. A refusal is a compensating deposit, so the ledger stays append-only and the round trip is legible in it: the sender's history reads `-96, +96` rather than going quiet.

### D3 — The handshake exists exactly when the initiator could not have made the deposit themselves

The obvious rule — "same party is immediate, different party waits" — gets the six cases wrong in both directions. Moving cargo from my ship into my own fleet's depot, where I am an officer, would need me to send myself a request and then approve it. Meanwhile "same party" would happily let a fleet member with read-only inventory access move stock between two fleet inventories.

The rule that gets all six right is about authorization, not identity:

> A transfer is **immediate** when the initiator is authorized to deposit into the named destination. Otherwise it names a **party**, and waits for them.

| from | to | immediate? |
|---|---|---|
| my inventory | my other inventory | always |
| a fleet inventory | the same fleet's other inventory | when the initiator holds `fleet:inventories:update` |
| my inventory | another user | never |
| fleet A | fleet B | only if the initiator is also privileged in B |
| my inventory | a fleet | when the initiator is privileged in that fleet |
| a fleet inventory | a user | only when that user is the initiator |

This grants nobody anything new. Every immediate case is one the initiator could already have performed as a manual withdrawal-plus-deposit; the transfer only makes it atomic and recorded as one event. Every case where they could not is the case that waits.

It also determines who fills in the destination. An immediate transfer names it at send time, because the sender is allowed to see it. A pending one cannot — see D8.

### D4 — One transfers table, with four nullable foreign keys

A cross-schema transfer has a source in one table and a destination in the other, so the two-table-per-level shape the rest of the subsystem uses has nowhere to put it. Three options, and the cheap-looking one is the one to avoid:

| | |
|---|---|
| two tables + a third for the crossing case | three shapes for one concept, and every read is a union. No. |
| one table, polymorphic `source`/`destination` | one shape, but **no foreign keys on either end** — and D13 depends on `ON DELETE RESTRICT` being a real backstop. |
| **one table, four nullable FKs** | one shape, four real foreign keys, exactly-one-per-side enforced by check constraints. |

**Corrected while building: the four are `ON DELETE SET NULL`, not `RESTRICT`.** `RESTRICT` was chosen here as a database-level backstop for D13, and it is wrong. `User has_many :inventories, dependent: :destroy` (`user.rb:163`), so a single *completed* transfer would make that user undeletable forever. A finished transfer holds no goods and must not restrain anything, and a foreign key cannot tell it from a pending one. The model can, and D13's guard is where a person gets a readable error anyway. Two of the check constraints go with it — "exactly one source" and "has a target" cannot survive a `SET NULL`, so they are model validations; "at most one" and "not to itself" stay in the database, because nulling a column can only make them more true.

The third. #4855 D3 chose two tables over one polymorphic one and named "two nullable FKs" as the alternative it did not need; this is the case that needs it, because the thing being pointed at is genuinely one of two types rather than consistently one.

```
id                             uuid pk
source_inventory_id            uuid  FK → inventories          ON DELETE SET NULL
source_fleet_inventory_id      uuid  FK → fleet_inventories    ON DELETE SET NULL
destination_inventory_id       uuid  FK → inventories          ON DELETE SET NULL
destination_fleet_inventory_id uuid  FK → fleet_inventories    ON DELETE SET NULL
recipient_id                   uuid  FK → users
recipient_fleet_id             uuid  FK → fleets
initiated_by_id                uuid  FK → users   not null
resolved_by_id                 uuid  FK → users
aasm_state                     string not null default "pending"
note                           text
expires_at                     datetime
completed_at / declined_at / cancelled_at / expired_at   datetime
created_at, updated_at
```

Constraints:

- exactly one source column set;
- at most one destination column set, and at most one recipient column set;
- a destination **or** a recipient, never neither;
- source and destination are not the same row (an inventory cannot transfer to itself);
- partial indexes on `(recipient_id) WHERE aasm_state = 'pending'` and `(recipient_fleet_id) WHERE aasm_state = 'pending'`, for the inbox and the cap in D9.

`#source` and `#destination` are readers over each pair, so nothing above the model deals in four columns.

### D5 — A transfer's lines *are* its ledger entries

No line table. Both item tables get a nullable `inventory_transfer_id` pointing at the one table from D4 — and because there is one table, there is one foreign key target rather than a pair of them.

The alternative is a line table holding `name`, `category`, `unit`, `quantity`, `quality`, `item_type`, `item_id` — which is the entry's own column list, stored twice, with the same drift problem #4855 D2 rejected for the rollups. What the shipment contains is *exactly* what left the source, and that is a set of rows that already exists.

Which side an entry is on is read from the pair it forms with the transfer, not from a column:

| the entry's inventory | `entry_type` | meaning |
|---|---|---|
| source | withdrawal | dispatched |
| destination | deposit | delivered |
| source | deposit | returned (declined, cancelled or expired) |

Unambiguous because source and destination are always different rows, per the check constraint in D4.

### D6 — Crossing schemas goes through `ledger_attributes_for`, and the executor never names a class

One `Inventories::TransferExecutor`, not one per direction. It reads the source entries, and for each one builds a deposit as:

```ruby
destination.inventory_items.new(
  carried_attributes(entry).merge(destination.ledger_attributes_for(actor))
)
```

`inventory_items` is the alias `InventoryStock.inventory_items_association` (`inventory_stock.rb:19`) already installs on both classes; `ledger_attributes_for` is the per-class hook from D1. So the executor is written once, works in all four combinations, and the only thing that knows a fleet entry has an `added_by` is `FleetInventory` — which already did.

`member_id` is deliberately **not** filled. It records which member the goods physically belong to, which a transfer from outside the fleet cannot know and must not guess.

### D7 — One state machine, five states, and an immediate transfer skips straight to the end

```
                  ┌─ accept  ─→ completed
pending ──────────┼─ decline ─→ declined
                  ├─ cancel  ─→ cancelled
                  └─ expire  ─→ expired

(an immediate transfer per D3 is created in `completed` — no pending row is ever written)
```

AASM with `timestamps: true` and `whiny_transitions: false`, matching `Oauth::Application` (`app/models/oauth/application.rb:64`) and `FleetMembership` (`fleet_membership.rb:160`). Four distinct terminal states rather than one `closed` with a reason column, because the notification, the wording and who is told differ per outcome, and the inbox filters on it.

`accept` is the only transition that takes an argument, and the only one that can fail on validation rather than on the state machine — the accepting party may name an inventory they do not hold.

### D8 — The destination of a pending transfer is chosen by the receiving side

A sender who is not authorized at the destination cannot name it. They may not be permitted to see it, it may not exist yet, and a ship inventory does not exist at all until its first deposit (`Inventory.provision_for`, `inventory.rb:60`). So a pending transfer carries a recipient and a null destination, and acceptance fills it in.

Who may accept:

| recipient | who |
|---|---|
| a user | that user, and only them |
| a fleet | any member with `fleet:inventories:update`, `fleet:inventories:manage` or `fleet:manage` |

The named destination is validated against **the acceptor**, not against the recipient recorded at send time. The two are the same in every legitimate case, and checking the acceptor is what stops a stale `recipient_id` from being a way to write into somebody else's inventory.

Accepting into a **ship** inventory provisions it inside the transaction, the way `InventoryScoped::ItemActions#create` does (`item_actions.rb:31`) — so a rejected acceptance cannot leave an empty inventory behind.

### D9 — One ordered gate, evaluated only where the handshake is

Everything that decides whether a stranger's transfer may reach you is one chain, in one class, evaluated in this order. First refusal wins:

| # | check | refused with |
|---|---|---|
| 1 | the recipient can actually use the feature (their flags) | "cannot receive transfers" |
| 2 | the **sender** is not under a platform transfer sanction | explicit — they need to know |
| 3 | the recipient's **policy** admits this sender | explicit — it is an announced stance |
| 4 | no **deny rule** names this sender | generic, per D11 |
| 5 | the recipient is under the outstanding-transfer cap | explicit — it is temporary |
| 6 | Rack::Attack has not throttled the sender | 429 |

The crucial scoping: **the gate runs exactly where the handshake does.** D3 says a transfer is immediate when the initiator could have made the deposit by hand, and a deposit you are authorized to make is not something a policy can refuse — you cannot block yourself, and an officer depositing into their own fleet is not "receiving" anything. So the gate has no say over immediate transfers, and that falls out of D3 rather than being a separate rule to keep in sync.

An **allow rule** (D10) short-circuits checks 3 and 5 — it is how "nobody, except these" is expressed, and how a trusted hauler stays reachable when an inbox is full. It does not short-circuit 1, 2 or 6: a sanction, a missing flag and a throttle are not the recipient's to waive.

### D10 — Policy is a stance; rules are exceptions to it

Two mechanisms, because the question has two shapes — "who in general" and "not this one".

**Policy** — one enum per party, `inventory_transfer_policy`, a column on `users` and on `fleets` alongside the boolean privacy columns already there (`public_hangar`, `hide_owner`, …):

| value | admits |
|---|---|
| `everyone` | any user or fleet *(default)* |
| `known` | a sender sharing a fleet with you; for a fleet, its own members |
| `nobody` | no incoming transfers at all |

Default `everyone`, deliberately. The request is to be able to *disable* incoming transfers, which presumes they are on; a default of `known` would make the feature's main use — settling up with a hauler you just met — fail silently for almost everybody, and the cap, the rules and the report queue are what contain the abuse. A fleet's policy is changed by `fleet:inventories:manage`; no new privilege, and the setting sits with the inventories it governs.

**Rules** — `inventory_transfer_rules`, a per-party allow or deny naming one other party. Same four-nullable-foreign-key shape as D4, for the same reason and so the idiom is stated once rather than twice:

```
id                uuid pk
user_id           uuid  FK → users     ON DELETE CASCADE   ┐ the party holding the rule
fleet_id          uuid  FK → fleets    ON DELETE CASCADE   ┘ exactly one
subject_user_id   uuid  FK → users     ON DELETE CASCADE   ┐ the party it names
subject_fleet_id  uuid  FK → fleets    ON DELETE CASCADE   ┘ exactly one
effect            integer not null        allow | deny
note              text
created_by_id     uuid  FK → users     not null
created_at, updated_at
```

Cascade rather than restrict, unlike D4: a rule about a deleted account is not evidence of anything, and there are no goods behind it. A unique index on each (party, subject) pair — one rule per relationship, flipped rather than stacked.

The two compose into the four useful stances without a fourth mechanism: `everyone` + denies is a blocklist, `nobody` + allows is an allowlist, `known` + allows is the common case, and `known` + denies covers the fleet-mate you would rather not hear from.

### D11 — A policy refusal is explicit; a personal denial is not

A sender told "this fleet does not accept transfers" has learned an announced organisational stance and can act on it. A sender told "this user has blocked you" has learned something personal about one account's opinion of them, which is the thing that invites retaliation and probing.

So checks 3 and 4 in D9 refuse differently on purpose: the policy names itself, the deny rule returns the same generic "cannot accept transfers" that a `nobody` policy would. This costs nothing and is the standard shape for a block.

Two consequences to build deliberately rather than discover:

- **A deny does not cancel what is already in flight.** Rules are forward-looking; a pending transfer sent before the deny stays pending, and the recipient declines it. The alternative — auto-declining on deny — returns goods the sender may not be expecting back and makes blocking a remote write into someone else's ledger.
- **Reporting *does* decline.** See D12.

### D12 — Reports, and the sanction they can lead to

Reporting is what makes the rest enforceable: a deny protects one recipient, and a spammer with a fresh target list is unaffected by it.

`inventory_transfer_reports` — the reporter (the recipient user, or a fleet member with `fleet:inventories:manage`), the transfer, a reason enum (`spam`, `harassment`, `scam`, `other`) and a note, plus an AASM state (`open` → `actioned` | `dismissed`), the reviewing `AdminUser` and their resolution note. One report per reporter per transfer.

Three properties it needs, and each is a decision:

1. **Reporting gives immediate relief, without an admin.** Filing a report declines the reported transfer (returning the goods, per D2) and writes a deny rule against the sender. The reporter is not left waiting on a queue for something they can already do themselves — the report is the *additional* step, not the only one.
2. **The evidence survives on its own.** A report points at a transfer, and a transfer's contents are its ledger entries (D5), which are never deleted. A declined, cancelled or expired transfer is still fully readable, so there is nothing to snapshot into the report and nothing for the sender to erase. This is a property the append-only ledger gives for free, and it is worth not breaking later.
3. **The queue is one row, not one per report.** `AdminNotification.notify!` with a `dedupe_key`, exactly as `Oauth::Application#report_for_review` does (`oauth/application.rb:113`) — and for the reason its comment already gives: anyone can sign up, so a per-record notification turns a spree into an inbox nobody reads. A new `inventory_transfer_reports` privilege in `AdminUser::RESOURCE_ACCESS` under `community` (`admin_user.rb:52`), beside `fleets` and `users`.

The sanction an admin can apply is `transfers_blocked_at` + `transfers_blocked_reason`, on `users` and on `fleets` — check 2 of D9. It is deliberately narrower than Devise's `locked_at`, which is already available and takes the whole account: a proportionate response to transfer spam should cost the account its transfers and nothing else.

**Not built: automatic sanctions.** No threshold of reports locks anyone out. At the volumes in *Worth knowing* a human reviewing every report is entirely feasible, and an automatic trigger is a way to weaponise the report button against an innocent account.
### D13 — Goods in transit block the two destroys that would strand them

Two existing operations would silently empty a pending shipment, because the withdrawal representing it is an ordinary entry:

- `dependent: :destroy` on an inventory's items (`inventory_stock.rb:19`) — destroying the source destroys the withdrawals, so accepting would deposit a shipment that no longer left anywhere.
- `destroy_stock_item` (`inventory_stock.rb:154`) destroys every entry of a position and then the position.

Both are refused while any affected entry belongs to a `pending` transfer, with an error naming the transfer. Not auto-cancelled: cancelling returns the goods to the inventory being destroyed, which is a contradiction, and doing it silently is the worst of the three options.

The four `ON DELETE RESTRICT` foreign keys in D4 are the backstop for anything that bypasses the model — and are the reason D4 rejected the polymorphic table.

### D14 — What the mirrored deposit copies, and the one thing it cannot

A line names a **position** and a quantity. The deposit copies `name`, `category`, `unit`, `item_type` and `item_id`, the last two from the position's reference entry (`inventory_stock.rb:188`), so the destination keeps the catalogue link and therefore the image rather than landing as a bare hand-typed name. This matters more across schemas than within one: a commodity donated to a fleet should arrive looking like that commodity.

`quality` is the exception. A position rolls up entries at several qualities — `quality_min`/`quality_max` exist precisely because mined ore comes in grades — and a line saying "32 of 96 SCU" cannot say *which* 32. So: copy `quality` when the position is uniform (`quality_min == quality_max`), null otherwise. Guessing a grade is worse than not recording one, and null is already the common case in the data.

A position renamed while a transfer is pending renames the shipment with it, because the withdrawal entries move with their position (`inventory_stock.rb:183`). That is correct — it is the same goods — and the deposit uses the labels as they read at accept time.

### D15 — Gated on `inventory_transfers`, *and* on the flags of every family the transfer touches

One new flag for all six movements: they are one feature, and shipping part of it is not useful.

It does not replace the three existing gates, and a cross-schema transfer is subject to **both** sides':

| transfer | flags |
|---|---|
| hangar → hangar | `inventory_transfers` + `hangar_inventories` |
| either end is a ship inventory | + `ship_inventories` |
| any end is a fleet inventory | + `fleet_logistics` |

Otherwise the new flag becomes a way around the old ones — a user could push stock into a fleet whose logistics are switched off.

Frontend gating goes through `FeatureFlagName` and, for the fleet side, new entries in `FleetMembership::CAPABILITY_PRIVILEGES` (`fleet_membership.rb:130`) — no flag strings and no privilege strings in the client.

### D16 — One deploy, nothing to backfill

New table, one nullable column on each item table. The previous release writes no transfers, so unlike #4855 there is no window in which the old code produces a row the new code cannot read. The migration runs in the pre-deploy hook before the new containers boot and adds no constraint to existing rows.

### D17 — Two notification types, and one existing notification that must not double up

`inventory_transfer_received` (to the recipient user, or to the destination fleet's inventory managers) and `inventory_transfer_resolved` (back to the initiator, carrying the outcome). Four types — one per terminal state — would triple the `Notification::TYPES` entries, the retention config and the translations for a distinction the body already makes.

The trap: `FleetInventoryItem` fires `notify_inventory_entry` on **every** create (`fleet_inventory_item.rb:50`). A ten-line transfer accepted into a fleet inventory would send ten "item added" notifications alongside the one transfer notification. Entries written by a transfer suppress it; the transfer notification is the event. Recipient resolution reuses that method's membership walk rather than copying it.

## What changes

### Phase 1 — The table and the state machine
1. Migration: `inventory_transfers` per D4 — four inventory foreign keys, two recipient foreign keys, the check constraints and the two partial pending indexes.
2. Migration: nullable `inventory_transfer_id` on `inventory_items` and on `fleet_inventory_items`, both with a foreign key and an index.
3. `InventoryTransfer` model: the AASM block, `#source`/`#destination` over the four columns, the source/destination/recipient validations, `immediate?` per D3, `has_paper_trail`, `ransackable_*`.

   **No `VersionedItem::ROOTS` entry, contrary to the plan.** `ROOTS` is what the admin version reader will accept, and an entry there without a matching `POLICIES` entry is dead — `authorization_root` returns nil and every read is denied — while still widening the public `itemType` enum. paper_trail records the versions either way; surfacing them needs an `Admin::InventoryTransferPolicy` and a feed entry, and the report queue already shows an admin the transfer and its entries. Deferred rather than half-built.
4. `transfer_association` on `InventoryLedgerEntry`, so both item classes reach it under one name.

### Phase 2 — The move itself
1. `Inventories::TransferExecutor` — writes the mirrored entries in one transaction, through the `inventory_items` alias and `ledger_attributes_for` per D6, and is the only place that knows the copy rules in D14.
2. `Inventories::TransferBuilder` — turns `[{positionId, quantity}, …]` plus a target into a transfer: resolves each position, checks each quantity against `stock_positions`, and rejects the whole set if any line fails. All-or-nothing; a partial unload is not something the UI could offer to undo.
3. `Inventories::TransferAuthorizer` — answers D3's one question ("could the initiator deposit here themselves?") for all six combinations, and is what both the builder and the policies call so the rule has one definition.
4. Immediate transfers run builder and executor in one transaction and land in `completed`.

### Phase 3 — The handshake
1. `accept` (with a destination), `decline`, `cancel`, and the guards on who may run each.
2. Ship-inventory provisioning inside the accept transaction.
3. `expires_at` on send (14 days) and `Inventories::ExpireTransfersJob`, daily in `config/sidekiq_schedule.yml`, returning the goods per D2.

### Phase 4 — The gate
1. Migration: `inventory_transfer_policy` on `users` and `fleets` (default `everyone`); `transfers_blocked_at` and `transfers_blocked_reason` on both.
2. Migration: `inventory_transfer_rules` per D10 — four cascading foreign keys, the two exactly-one check constraints, and the unique index per (party, subject).
3. `Inventories::TransferGate` — the six ordered checks in D9, returning a typed refusal so the controller can render the explicit ones and the generic one per D11. It consults `TransferAuthorizer`, so an immediate transfer never reaches it.
4. The outstanding-incoming cap and the Rack::Attack rule, as checks 5 and 6 — the throttle alongside the existing `oauth-application-registration` one (`config/initializers/rack_attack.rb:34`), which is the same argument about one account producing a queue in one burst.

### Phase 5 — Reports and the sanction
1. `InventoryTransferReport` per D12: reason enum, AASM state, reviewer, resolution note, one per reporter per transfer.
2. Filing a report declines the transfer and writes the deny rule, in one transaction.
3. `AdminNotification` with `dedupe_key: "inventory_transfer_reports"`, and the new privilege in `AdminUser::RESOURCE_ACCESS[:community]`.
4. Admin API + admin page: the open queue, the transfer's lines as evidence, and the two actions — sanction the sender, or dismiss.

### Phase 6 — The guards
1. The two destroy refusals in D13, with their messages in all seven locales.
2. `ON DELETE RESTRICT` on the four inventory foreign keys.

### Phase 7 — API
1. Routes under `hangar/` and `fleets/:slug/`: `index`, `show`, `create`, and `put :accept` / `put :decline` / `put :cancel` / `post :report` on the member — matching how `fleet_members` / `fleet_memberships` already expose transitions (`config/routes/api/fleets_routes.rb:22`). Two mount points, one controller concern; which one you call decides the *source*, and the payload decides the target.
2. `InventoryTransferScoped` holding the action bodies, the way `InventoryScoped::ItemActions` does for entries.
3. Settings endpoints: the policy on `me` and on the fleet, and CRUD for transfer rules under both.
4. Policies: `HangarInventoryTransferPolicy`, `FleetInventoryTransferPolicy`. Send authorizes against the source, accept against the destination, and both delegate the D3 question to the authorizer and the D9 question to the gate.
5. Schemas in `app/api_components/v1/`: `InventoryTransfer`, `InventoryTransferLine`, `InventoryTransfersList`, `InventoryTransferRule`, the state / policy / report-reason enums, a `TransferPartyRef` that is a user or a fleet, and the create / accept / report inputs. Then `./bin/generate-schema` and an `oasdiff` check.
6. Jbuilder views, reusing `_stock_position.jbuilder` for each line's position.

### Phase 8 — Notifications
1. Two `notification_type` enum values with `TYPES` entries, translations in all seven locales, and the `notify_inventory_entry` suppression from D17.
2. Accept, decline and report as notification call-to-actions.

### Phase 9 — Frontend
1. `TransferModal` — multi-select over the source inventory's stock positions with a per-line quantity defaulting to the full net, then a target step offering my inventories, my fleets' inventories, another user, or another fleet. Whether the destination picker or the party picker is shown comes from the API, not from a rule reimplemented in the client.
2. A transfers list with incoming and outgoing tabs, under `hangar/` and under fleet logistics; the accept flow asks for the destination inventory; decline and report sit beside it.
3. A "goods in transit" marker on the source inventory panel, so escrowed stock is visibly somewhere rather than simply gone.
4. Settings: the policy selector and the rules list, in user settings and in fleet settings, plus "block this sender" as one action from a received transfer.
5. Route `meta.title` in both the `nav.*` and `title.*` namespaces, and every string — including every refusal message — in all seven locale files.

### Phase 10 — Tests
Written per phase. The state machine and both destroy guards; the D3 authorizer across all six combinations, positive and negative; **the gate as a table test over policy × rule × sanction × cap**, asserting the refusal *shape* as well as the outcome, since D11 makes the wording load-bearing; a concurrency test that two transfers racing the same stock cannot both send; integration tests per endpoint, including a cross-schema round trip in each direction, the cross-party 403s, and accepting into an inventory the acceptor does not hold; report-declines-and-denies in one transaction; a job test for expiry returning the goods; Vitest for the modal's quantity validation; one Playwright pass over the immediate unload.

## Intent Verification

- [ ] **One move is one event** — an immediate transfer writes both entries in one transaction, and either both land or neither does.
- [ ] **All six movements work** — including both crossings, verified as a round trip that leaves both ledgers consistent.
- [ ] **Crossing schemas loses nothing** — a deposit into a fleet inventory carries the catalogue reference and gets its `added_by`; one into a user inventory does not acquire columns it has no place for.
- [ ] **Several positions at a time** — one transfer carries N lines and produces 2N entries, and a single bad line rejects the whole set.
- [ ] **The handshake rule holds** — a transfer is immediate in exactly the cases where the initiator could have made the deposit by hand, and pending in every other.
- [ ] **No new authority** — no immediate transfer performs a write its initiator could not already have performed as a withdrawal plus a deposit.
- [ ] **The gate cannot reach an immediate transfer** — moving stock between your own two inventories is unaffected by any policy, rule, sanction or cap.
- [ ] **Every stance is expressible** — blocklist, allowlist, fleet-mates-only and closed, each from policy plus rules, with no fourth mechanism.
- [ ] **A refusal says the right amount** — a policy refusal names itself; a deny rule is indistinguishable from a closed policy, so a sender cannot probe for a personal block.
- [ ] **A report gives relief without an admin** — filing one declines the transfer, returns the goods and denies the sender, in one transaction.
- [ ] **The queue stays readable** — a hundred reports produce one admin notification row, not a hundred.
- [ ] **The sanction is proportionate** — a transfer-blocked account can still do everything else it could before.
- [ ] **Escrow is real** — after a send, the source's `stock_positions` is reduced immediately, and a second send of the same goods is refused.
- [ ] **Acceptance cannot fail for want of stock** — the goods have already left; accepting only ever deposits.
- [ ] **A refusal returns the goods** — decline, cancel and expire each restore the source to its pre-send net, by deposit and not by deletion.
- [ ] **The recipient chooses where it lands** — a pending transfer's destination is null until acceptance, and an accept naming an inventory the acceptor does not hold is refused.
- [ ] **Nothing in transit can be stranded** — destroying the source inventory, or the position, is refused while a pending transfer holds its entries.
- [ ] **The ledger is still append-only** — no transfer path issues a `DELETE` or edits an entry's quantity, and a reported transfer stays fully readable as evidence.
- [ ] **The old gates still hold** — `inventory_transfers` alone opens no hangar, ship or fleet inventory whose own flag is closed, on either end.
- [ ] **One notification per event** — accepting a ten-line transfer into a fleet inventory sends one notification, not eleven.
- [ ] **No breaking schema change** — `oasdiff` 1.18.1 against main reports nothing new, with no added ignore entries.

## Key files

| File | Role |
|------|------|
| `app/models/concerns/inventory_stock.rb` | `ledger_attributes_for` (`:33`) — the hook D6 turns into the cross-schema bridge; the rollups a transfer reads (`stock_positions:57`); the two destroys D13 guards (`destroy_stock_item:154`) |
| `app/models/concerns/inventory_ledger_entry.rb` | The entry shape a transfer writes; `assign_position` (`:249`), `withdrawal_does_not_exceed_stock` (`:310`) and the lock order its comment fixes (`:267`) |
| `app/models/inventory.rb` | `provision_for` (`:60`) — a ship destination is brought into existence inside the accept transaction |
| `app/models/fleet_inventory.rb` | `ledger_attributes_for` (`:72`) — the `added_by` half of D6 |
| `app/models/fleet_inventory_item.rb` | `notify_inventory_entry` (`:60`) — reused for recipients, suppressed for transfer entries (D17) |
| `app/models/fleet_membership.rb` | `has_access?` (`:120`) — what D3 asks on the fleet side; `CAPABILITY_PRIVILEGES` (`:130`); the AASM idiom (`:160`) |
| `app/models/oauth/application.rb` | The AASM idiom this follows (`:64`), and the deduped admin review queue D12 copies (`:113`) |
| `app/models/admin_user.rb` | `RESOURCE_ACCESS` (`:52`) — where the report-queue privilege is registered |
| `app/models/user.rb` / `app/models/fleet.rb` | Where the policy and sanction columns join the existing privacy booleans |
| `config/initializers/rack_attack.rb` | The per-endpoint throttle precedent (`:34`) check 6 follows |
| `app/controllers/concerns/inventory_scoped/item_actions.rb` | Provisioning inside the transaction (`:31`) — the accept path copies it |
| `app/controllers/concerns/vehicle_inventory_scoped.rb` | How a ship inventory resolves, and why scoping is the authorization boundary |
| `app/policies/{hangar,fleet}_inventory_item_policy.rb` | The two policy families, one per end of a crossing transfer |
| `config/feature_flags.yml` | The three existing gates (`:30`, `:42`, `:47`) the new one composes with |
| `config/sidekiq_schedule.yml` | Where the expiry sweeper is registered |
| `app/models/notification.rb` | `notification_type` enum (`:39`) and `TYPES` (`:66`) |
| `app/api_components/v1/schemas/inventory_stock_position.rb` | The position shape each line embeds |
| `app/frontend/frontend/components/Logistics/` | `StockItemPanel`, `InventoryItemModal`, `InventoryPanel` — where the action and the in-transit marker go |
| `app/frontend/admin/pages/` | Where the report queue page goes, beside `users` and `fleets` |
| `app/frontend/translations/*/` | Seven locales, hand-written; there is no key-parity check in CI |

## What the build corrected

Recorded here rather than silently, because each was a decision this plan got wrong:

| decision | what changed | why |
|---|---|---|
| D4 | `ON DELETE RESTRICT` → `SET NULL` on the four inventory keys, two check constraints → model validations | `RESTRICT` would make a completed transfer block deleting its owner forever |
| Phase 1 | no `VersionedItem::ROOTS` entry | an entry with no policy is dead and still widens a published enum |
| D9 | the gate's six checks became five | the throttle is Rack::Attack's, which runs before the controller — it was never a step the gate could evaluate |

Still to do, and not in this change: the fleet-side and settings frontend (the policy selector, the rules list, and "block this sender"), the admin report-queue page, and the Rack::Attack rule. The API for all of them is in place and tested; only the screens are missing.

## Not in scope (deferred)

- **A general block list.** The rules in D10 govern transfers and nothing else. A block that also hid you from fleet search, member lists and mission signups is a bigger, cross-cutting feature; this is deliberately the narrow version, shaped so a general one could absorb it later.
- **Automatic sanctions** — D12. No report threshold locks anyone out; a human reviews.
- **Partial acceptance.** A recipient takes the whole shipment or none of it. Splitting one transfer across two destinations, or accepting 20 of 32 SCU, doubles the state machine for a case nobody has asked for.
- **A bespoke ship-to-ship cargo screen.** The generic transfer already performs the move; a dedicated presentation is a later question.
- **Anything priced.** No payment, no aUEC, no escrowed currency. A transfer moves goods one way.
- **Transfers as a fleet-event or mission artefact** (a hauling contract that settles by transfer). Real, and reachable from here, but it belongs with the mission builder.

## Worth knowing

Measured against the current production dump, so the risk is sized honestly:

| | count |
|---|---|
| `inventories` | 1 (a ship inventory) |
| `inventory_items` | 1 |
| `fleet_inventories` | 9, across 7 fleets |
| `fleet_inventory_items` | 11 |
| fleets holding more than one inventory | 2 |
| fleets / users in total | 13,902 / 59,946 |

Nobody would notice if this shipped broken, which is an argument for building it carefully rather than urgently. It is also the argument for the cross-party cases being the ones that matter: the same-user movement has exactly one candidate today and the same-fleet movement has two, while "send someone cargo" is the only one of the six that gives a second inventory a reason to exist.

Those same numbers size the moderation load, and they are why D12 has a human in it. A report queue reviewed by hand is feasible at any volume this feature can plausibly produce for a long time; an automatic trigger built now would be tuned against no data at all.
