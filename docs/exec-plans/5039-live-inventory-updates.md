# Live inventory updates for fleet, hangar and ship inventories

## Goal

A deposit, withdrawal, correction, transfer, position rename or merge updates every open page showing that stock — a fleet's logistics pages, a member's own hangar and ship inventories, and the held-material rows on blueprint detail — without a reload.

## Context

Inventory contents have no live updates. This matters most for a fleet's shared stores, where several members act on the same stock at once, and is a welcome extra for a member's own inventories. On blueprint detail the staleness is silent: `useMaterialStock` answers "you hold 101 SCU of this on the Avenger" from a snapshot taken when the page opened.

Blocked on #5038 until it merged: a per-user fan-out has to know who may see an inventory, and building it against an unenforced `officers_only` would have baked that gap into the broadcast audience. `FleetInventory#visible_to?` now answers exactly that.

Resolves #5039

## Decisions

### D1 — One hook on the inventory, not on the ledger entry

`inventory_association` declares `belongs_to association_name, touch: true` (`inventory_ledger_entry.rb:145`), so every entry create, update and destroy touches its inventory. The two bulk paths that bypass entry callbacks touch explicitly as well — `update_stock_item` after `move_position`'s `update_all`, and `destroy_stock_item` after its `destroy_all`.

So a single `after_commit` in the shared `InventoryStock` concern covers deposits, withdrawals, corrections, transfers, renames and merges. An entry-level hook — the obvious first instinct — would silently miss every position rename, because `update_all` runs no callbacks.

`InventoryStock` is included by both `Inventory` and `FleetInventory`, so hangar and fleet come from the same hook. The fan-out differs per holder, so the concern declares the callback and each model implements it.

### D2 — Two per-user channels

Channels here take no params — every one is `stream_for current_user` — so a fleet inventory cannot be keyed by fleet. `HangarInventoryChannel` and `FleetInventoryChannel`, both per-user, with the fleet one fanned out across its audience. That is the shape `FleetMembership#on_accept_invitation` already uses.

### D3 — The audience is the visibility rule, not the membership list

`FleetVehiclesChannel` broadcasts to every kept membership. Inventories are gated, so the fan-out asks the same two questions the endpoints ask: the read privileges, and `visible_to?(membership)` — the rule #5038 established. A member who cannot read an officers-only store is not told when it changes.

`READ_PRIVILEGES` moves from `FleetInventoryPolicy` to `FleetInventory` beside `OFFICER_PRIVILEGES`, so the model does not reach into a policy for it. The policy keeps referencing it, as it already does for `OFFICER_PRIVILEGES`.

### D4 — A ping, not the rows

The page's unit of interest is a rolled-up position (`SUM ... GROUP BY` across the all-stock controllers), not the entry that changed, so shipping rows would mean reimplementing the aggregate in the broadcast. The payload names the inventory and lets the client refetch.

It still carries an identity rather than being empty: a per-inventory page can ignore a ping for a different store. `HangarGroupChangedMessage` is the precedent — a ping needs a shape no other message on the channel can satisfy, or declaring it as an alternative stops the other contract being enforced.

### D5 — Debounce on the client

`touch` fires per entry, so a bulk deposit or an accepted transfer produces a burst. `useDebouncedRefresh` already exists and is what `pages/hangar/index.vue` uses. Reconnect refetches too: the channel replays nothing broadcast while the socket was down.

### D6 — One composable, several callers

`useInventoryUpdates` owns both subscriptions and the debounce; each page passes what to do. Keeps the subscription details in one place rather than in five.

## What changed

### Phase 1 — The broadcast

1. `Cable::V1::Schemas::HangarInventoryChangedMessage` and `FleetInventoryChangedMessage`.
2. `HangarInventoryChannel`, `FleetInventoryChannel`.
3. `READ_PRIVILEGES` onto `FleetInventory`; `FleetInventoryPolicy` references it.
4. `after_commit :broadcast_inventory_change` in `InventoryStock`, implemented per model.
5. Declarations in `test/asyncapi/`, then `bin/generate-asyncapi` and `bin/generate-cable-client`.

### Phase 2 — The pages

6. `useInventoryUpdates` — both subscriptions, debounced, refetch on reconnect.
7. `useMaterialStock` — invalidate the hangar and fleet stock queries.
8. `hangar/inventories` index and `[inventory]`.
9. `fleets/[slug]/logistics` index, `inventories/[inventory]`, `transfers`.

### Phase 3 — Coverage

10. asyncapi broadcast tests per channel (the declaration file is also the test).
11. A fan-out test: an officers-only store notifies officers and its manager, not a plain member.
12. A test that a position rename broadcasts — the case an entry-level hook would miss.
13. Vitest for `useInventoryUpdates`.

## Intent Verification

- [ ] A deposit, withdrawal, correction, rename, merge or transfer updates an open fleet logistics page without a reload
- [ ] The same for a member's own hangar and ship inventories
- [ ] Blueprint detail held-material rows and quality marks follow an inventory change live
- [ ] The fleet fan-out reaches only members permitted to read that inventory, `officers_only` included
- [ ] A burst of entries produces one refetch, not one per entry
- [ ] Reconnecting after a dropped socket refetches rather than waiting for the next change
- [ ] `asyncapi/` regenerated and committed; both generators run

## Key files

| File | Role |
|------|------|
| `app/models/concerns/inventory_stock.rb` | The one hook, for both inventory kinds |
| `app/models/concerns/inventory_ledger_entry.rb` | `touch: true` — why that hook is enough |
| `app/models/fleet_inventory.rb` | `visible_to?`, and the fan-out audience |
| `app/models/inventory.rb` | The hangar/ship fan-out — one holder |
| `app/channels/` | The two new channels |
| `test/asyncapi/` | Declaration and test in one file; generates the schema |
| `app/frontend/frontend/composables/useMaterialStock.ts` | What the blueprint page reads |
| `app/frontend/shared/composables/useSubscription.ts` | The subscription helper the pages use |

## Not in scope (deferred)

- **Shipping the changed rows** — see D4
- **Admin inventory pages** — no live expectation there
- **`fleet:logistics:manage`**, a privilege in `notify_inventory_entry` that is not in the roles enum and can never match. Noted in #5038, still not this change's business.

## Discovery Log

- **2026-09-19** Issue filed with the design, blocked on #5038.
- **2026-09-19** #5038 merged, so the audience rule exists. Re-confirmed on main that the touch chain is intact and no inventory channel exists.
- **2026-09-19** The asyncapi document is generated, not hand-written: `bin/generate-asyncapi` runs `asyncapi_cable:generate` over `test/asyncapi/**/*_test.rb`, where each file both declares a channel and tests its broadcast. So Phase 1 and Phase 3 are the same files.
- **2026-09-19** PR #5048 (`feat/5043-blueprint-owned-and-fleet-view`) touches `blueprints/[slug].vue` but not `useMaterialStock.ts`. `pieceVolume` already landed on main.
- **2026-09-20** The subscription could not live inside `useMaterialStock` after all: `BlueprintSlot` instantiates it once per recipe slot, so a page would have opened the same channel four to eight times. The queries are shared through the vue-query cache; a subscription is not. `useMaterialStockUpdates` is exported beside it and called once from the page instead — which does mean a two-line touch to `[slug].vue`, the one file PR #5048 also edits.
- **2026-09-20** The generated TS cable client is gitignored (`.gitignore:38`) and rebuilt by `postinstall`, so only `asyncapi/cable/v1/schema.yaml` is committed. CI regenerates the channel classes from it.
- **2026-09-20** `ConnectEvent` reports `reconnect` as optional, not boolean — restating the shape inline was a type error rather than a style choice.
- **2026-09-20** The transfers list subscribes unfiltered on purpose: a transfer moves stock at both ends and the far end is usually an inventory that view is not scoped to.
- **2026-09-20** A new channel class is not only an asyncapi change: the REST schema carries an enum of channel names, so `swagger/v1` and `swagger/admin/v1` both gained two entries. `api-schema-check` runs both generators and demands a clean diff, so it caught this — `bin/generate-asyncapi` alone was not enough.
- **2026-09-20** Running `bin/generate-schema` on macOS also relocates `components.parameters` from after `securitySchemes` to before it — the same content, moved. That is a platform artifact, not a change: committing it would have reddened the check on CI's Linux. Only the four enum lines per document were applied, by hand.
- **2026-09-20** Review round. Five findings, all valid. The hangar views subscribed without discriminating the source, and a slug is unique only within its holder (`(holder_type, holder_id, slug)` and `(fleet_id, slug)` are separate unique indexes) -- so a fleet store named "Refinery" matched the reader's own one on the hangar detail page. Both hangar callers now require `fleetSlug === undefined`.
- **2026-09-20** A ping runs after the write it reports has committed, and an exception in an `after_commit` reaches the caller -- so a pubsub backend that is down turned a deposit that landed into a deposit that raised, and in the fleet loop cost every member after the first their notification. `broadcast_safely` wraps each recipient. Scoped to the new fan-outs: Vehicle's and FleetMembership's broadcasts carry the same exposure, and changing the app's posture wholesale is not this change's business.
- **2026-09-20** `AGENTS.md:163` asks for interfaces over type aliases; `InventoryChange`, `Options` and the spec's `Handler` were converted.
- **2026-09-20** minitest 6 dropped `stub` and the suite pulls in no mocking library (mocha is in the Gemfile but `require: false`). Overriding `broadcast_to` on the channel class and removing the override again restores the inherited one, which matches how the model tests fake collaborators.

## Progress

- [x] Phase 1 — The broadcast
- [x] Phase 2 — The pages
- [x] Phase 3 — Coverage
