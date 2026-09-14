# Premium fleet features — a subscription a fleet buys, held in its own record

## Goal

A fleet subscribes, and the premium features switch on for every member without any of them paying
individually or toggling anything. The entitlement is a first-class record with a period and an audit
trail — not a feature flag — so it can be granted, revoked, comped, and answered for.

`fleet_contracts` (#4890) is the first and, on landing, the only feature behind it.

## Context

The platform already has the money half and has never connected it to anything.

`SupporterContribution` records an amount, a currency, `recurring`, and a `started_at`/`ended_at` pair.
`Patreon::SupporterImporter` syncs the campaign, ends churned patrons, and fires
`Notifications::NewPatronJob`. `User#supporter?` exists at `app/models/user.rb:493` under a comment that
reads, in as many words, *"Gate perks on this one"*.

Nothing gates on it. The only reader of a contribution anywhere in the app is `public_supporter?`,
which renders a badge.

And it could not, because of one missing column. Measured against the production dump:

| | |
|---|---|
| Contributions active this month | 3 (all Patreon) |
| ...with a `user_id` | **0** |
| All contributions ever, with a `user_id` | **0 of 16** |
| Users / fleets | 59,946 / 13,902 |

`SupporterImporter#assign_defaults` sets `source`, `anonymous`, `recurring` and `started_at`. It never
sets `user_id`, and the admin link field has never been used. `supporter?` is `false` for every account
in production, including the three that pay.

So there are two problems, and they are independent: **who paid** (identity), and **what paying buys**
(entitlement). Identity comes first because nothing else can be tested without it.

Money arrives through four links in `SupportBtn/Modal` — Patreon, PayPal, Ko-fi and Buy Me a Coffee —
and they do not resemble each other. Patreon has an API the importer already uses. Ko-fi has a webhook.
PayPal and Buy Me a Coffee have neither. Identity therefore has more than one mechanism, and D4–D6
choose one per platform rather than forcing a single flow onto all four.

## Decisions

### D1 — Flipper answers rollout. It never answers entitlement

The tempting shortcut is a `supporters` Flipper group: one gate toggle per flag and no code. It is the
wrong tool, for reasons that are structural rather than stylistic:

- **Deploys prune gates.** `bin/feature-flags sync` runs from `.kamal/hooks/pre-deploy` and removes
  flags not in the registry *including all of their gate values*. Paid access must not be coupled to a
  deploy-time reconciliation job.
- **Gates only grant.** Flipper ORs every gate, so there is no way to express a revocation. A stray
  actor gate from a support ticket silently becomes a permanent free subscription.
- **No audit.** A flag records who has it now, never who had it when, or why, or who granted it.
- **The admin toggle becomes the billing surface.** `/admin/features` is operated for rollouts. One
  misclick there would be a refund conversation.

So the two questions stay separate and both must pass:

| question | answered by | on failure |
|---|---|---|
| Is this feature rolled out here? | Flipper, unchanged | `forbidden` — "not available" |
| Has this fleet bought it? | `FleetSubscription` | `subscription_required` — an upsell |

Flipper never learns the word premium; the entitlement layer never learns about rollout.
`fleet_contracts` keeps its flag from #4890 D8 and keeps using it for exactly what a flag is for.

### D2 — `FleetSubscription` is the entitlement record

```
fleet_subscriptions
  fleet_id                   → fleets, not null
  started_at                 date, not null
  ended_at                   date, nullable — open while nil
  source                     enum: patreon | kofi | manual
  supporter_contribution_id  → supporter_contributions, nullable
  note                       text
```

A row is the grant. `ended_at` is the revocation, and both are dated, so the history is the table
rather than a reconstruction. `has_paper_trail` with `author_id` records who changed one, the way
`SupporterContribution` already does for admin edits.

One active subscription per fleet, enforced in the database rather than by a validation:

```sql
CREATE UNIQUE INDEX index_fleet_subscriptions_on_active_fleet
  ON fleet_subscriptions (fleet_id) WHERE ended_at IS NULL;
```

`source: manual` is not an afterthought — it is how a partner org gets comped, how a support ticket is
answered, and how a PayPal or Buy Me a Coffee supporter is honoured at all.

### D3 — One flat tier, and no plan column

A fleet is subscribed or it is not. The subscription covers whatever the premium set currently
contains, which on day one is contracts alone.

No `plan` column, no plan table, no per-feature pricing. `Subscriptions::PREMIUM_FEATURES` is a frozen
array of capability keys in one file, and a second tier later is one nullable column plus a join —
cheap precisely because nothing today reads a plan it would have to start honouring.

The qualifying amount is a single configured figure in EUR cents. `SupporterImporter#apply_amount`
already normalises USD to EUR through `ExchangeRateFetcher` and stores both figures, so the comparison
needs no conversion at read time.

### D4 — Patreon links by verified email. There is no key on Patreon

**Patreon API v2 exposes no patron-written field.** `note` is documented as *"The creator's notes on
the member"*; there is no pledge message, survey response or patron comment on the Member resource. A
key typed into a Patreon pledge message is invisible to the API, and no amount of instructions to
supporters changes that.

What is available is `email`, under the `campaigns.members[email]` scope. The importer links a
contribution to the account whose **confirmed** email matches it.

This is safe in a way a user-entered email is not: neither side is a claim. Patreon verified the
address for billing, Fleetyards verified it at confirmation, and the match is between two independently
verified records with no user assertion in between. An unconfirmed account never matches.

Ops note: the existing access token has to be reissued with `campaigns.members[email]`, or the field is
simply absent from the payload — a failure mode indistinguishable from "no patron matched". Phase 1
logs the distinction rather than leaving it to be discovered.

### D5 — The claim key is for the platforms that carry a donor message

PayPal, Ko-fi and Buy Me a Coffee all let the payer write a message, and all of them show it to the
recipient. That is the field Patreon does not have, and it is where the key goes.

`users.claim_key`, generated lazily, unique, shown in settings beside the support links. Crockford
base32 in a `FY-XXXX-XXXX` shape — no ambiguous characters, ~40 bits, regenerable if it leaks. Matched
case-insensitively with separators stripped, so a supporter who types `fy7k2m9qxd` is still found.

The key is per **user**, not per fleet. A per-fleet key would name the fleet in the payment and could
then only be re-pointed by making another payment; a user key plus an in-app nomination (D7) re-points
instantly.

Email is the fallback on these platforms too, and the key takes precedence where both match — the key
is a deliberate act, the email is a coincidence.

### D6 — Ko-fi's webhook makes the key automatic; PayPal and Buy Me a Coffee stay hand-entered

Ko-fi posts a webhook per payment carrying `message` (the donor's own text), `email`, `amount`,
`currency`, `is_subscription_payment`, `tier_name`, `kofi_transaction_id` and a `verification_token`,
as form-encoded JSON under a single `data` field. Every input the key mechanism needs arrives without
anyone touching anything.

So Ko-fi gets a real endpoint: verify the token, upsert a `SupporterContribution` keyed on
`kofi_transaction_id`, resolve the key from `message`, fall back to email. `is_subscription_payment`
maps onto `recurring`, which the model already has.

PayPal and Buy Me a Coffee have no webhook worth building against for this, so their contributions stay
hand-entered — with the key pasted from the payment note, which is the same resolution path and no new
code. At three active supporters that is proportionate; if either grows, it gets an endpoint of its
own rather than a workaround now.

The endpoint is public and unauthenticated by nature: constant-time token comparison, a throttle, and
no information in the response beyond acceptance.

### D7 — The supporter nominates the fleet in the app

A linked supporter picks which fleet their subscription covers, in settings.
`supporter_contributions` gains a nullable `fleet_id` for that nomination.

The derived alternative — *any accepted admin of the fleet is a supporter* — fails in both directions:
a supporter who admins five fleets would upgrade all five, and a fleet would lose its features when an
admin who was never the payer leaves. Sponsorship is a fact about the money, not about the roster.

One fleet per contribution. Someone covering two fleets has two contributions, which is also how they
would pay for two.

### D8 — The importers propose; the subscription record decides

`Subscriptions::Sync` runs after an import or a webhook and reconciles:

| contribution | subscription |
|---|---|
| active, nominated, at or above the amount | open one if the fleet has none |
| lapsed, un-nominated, or dropped below | close the open one it seeded (`ended_at`) |
| `source: manual` | **never touched** |

No importer writes a subscription itself, and `SupporterImporter` keeps its current job unchanged — it
syncs contributions, and something else reads them. Two reasons: a manual grant must survive a sync
that knows nothing about it, and reconciliation has to run when a *nomination* changes too, which is
not a payment event at all.

`supporter_contribution_id` is what makes "close the one it seeded" expressible. A subscription with no
contribution behind it is manual by construction and is left alone.

### D9 — Enforcement is a `before_action`, beside the flag check and after it

```ruby
before_action :check_fleet_contracts_feature
before_action :require_fleet_subscription
```

A concern, `FleetSubscriptionConcern`, mirroring `InventoryTransfersFeatureConcern` — the shape this
codebase already uses for exactly this job. One greppable line per controller, no policy branch, and no
service learning about money.

The order carries meaning. A feature that is not rolled out answers "not available" to everyone,
subscribed or not; only a feature that *is* rolled out and unbought answers with an upsell. Reversed, a
fleet would be sold something they could not yet have.

### D10 — Lapse is a read, not a job

No expiry sweep and no state column. `Fleet#subscribed?` is
`fleet_subscriptions.active_on(Date.current).exists?` — `started_at <= date AND (ended_at IS NULL OR
ended_at >= date)` — memoised per instance.

When D8 closes a subscription the next request stops granting; when it reopens one the next request
grants. The same argument #4890 D1 makes for contract progress: a thing computable from the record
should not also be stored where the two can disagree.

Memoisation is not a detail. `Fleet#features` and `Frontend::BaseController` iterate every flag in the
registry per request, and any entitlement read landing inside that loop multiplies by the flag count.
Asserted with a query-count test, not left to inspection.

### D11 — A refusal has to say it is a price, not a fault

Today an unavailable feature renders `{code: "forbidden", message: "This feature is not available"}`,
which for an unbought feature reads as broken and gives the frontend nothing to offer.

Premium refusals render `subscription_required`, which the frontend turns into a link to the support
page. The existing code is untouched for every non-premium gate.

Two constraints, neither optional: the code is a **literal** string at every site — an interpolated one
ships `translation missing` silently — and it needs an entry in all seven locale files by hand, because
there is no Crowdin and no CI check for locale parity.

### D12 — A fleet is told before it finds out from a 403

Losing features silently is the worst version of this. Two notification types, to the fleet's admins:
`fleet_subscription_started` and `fleet_subscription_ended`, the second carrying what lapsed and why.

No notification for a nomination change — that is the supporter's own action, in their own settings.

## What changes

### Phase 1 — Patreon identity
1. `Patreon::Member` gains `email`; `MEMBER_FIELDS` gains it; the access token is reissued with
   `campaigns.members[email]` per D4.
2. `Supporters::Linker` — confirmed-email match, idempotent, called per member from the importer.
3. A missing `email` field is logged as a scope problem, distinctly from an unmatched patron.

### Phase 2 — The claim key
1. Migration: `claim_key` on `users`, unique, nullable — generated on first view, the way
   `calendar_feed_token` already is.
2. `Users::ClaimKey` — generation over the Crockford alphabet, and the normalising match.
3. `Supporters::Linker` gains the key arm, taking precedence over email per D5.
4. Settings shows the key, what to paste it into, and a regenerate action.

### Phase 3 — Ko-fi
1. A webhook endpoint per D6: constant-time `verification_token` check, throttle, form-encoded `data`.
2. `Kofi::PaymentImporter` — upsert on `kofi_transaction_id`, `is_subscription_payment` → `recurring`,
   resolve through `Supporters::Linker`.
3. Migration: `kofi_transaction_id` on `supporter_contributions`, unique partial index matching the
   `patreon_member_id` one; `kofi` joins the `source` enum.

### Phase 4 — Nomination
1. Migration: `fleet_id` on `supporter_contributions`, nullable, foreign key, indexed.
2. `belongs_to :fleet, optional: true`; the column joins the `has_paper_trail` `only:` list and
   `ransackable_attributes`.
3. A supporter nominates one of their fleets, and can change or clear it.

### Phase 5 — The subscription record
1. Migration per D2, including the partial unique index.
2. `FleetSubscription`: `active_on` scope, `source` enum, paper trail, a `VersionedItem::ROOTS` entry.
3. `Fleet#subscribed?` / `#active_subscription`, memoised per D10.
4. `Subscriptions::PREMIUM_FEATURES` and the qualifying amount, in one place.

### Phase 6 — Reconciliation
1. `Subscriptions::Sync` per D8, run after `PatreonSupporterSyncJob`, after a Ko-fi payment, and on a
   nomination change.
2. Manual subscriptions excluded by construction — asserted, not assumed.

### Phase 7 — Enforcement
1. `FleetSubscriptionConcern` with `require_fleet_subscription`, rendering `subscription_required`.
2. Applied to the contracts controllers, after the flag check per D9.

### Phase 8 — Admin
1. Subscriptions CRUD under the existing `community` section beside `supporters`: open, close, comp,
   with a reason recorded through the paper trail.
2. The contribution list shows its nominated fleet, its resolved user, and whether a subscription was
   seeded from it.

### Phase 9 — API and frontend
1. Subscription status on the fleet payload; the premium set exposed so the UI can mark what a
   subscription would unlock.
2. The upsell on `subscription_required`, the settings surfaces from Phases 2 and 4, and every string
   in all seven locales with `%{}` placeholders — this is i18n-js, not vue-i18n.
3. `./bin/generate-schema` after a server restart, then orval for both clients, then `oasdiff`.

### Phase 10 — Notifications
Two types per D12, their `TYPES` entries, retention and preference defaults, and seven locales.

### Phase 11 — Contracts as the first premium feature
1. `fleet_contracts` added to `PREMIUM_FEATURES` once #4890 has merged.
2. Confirm the composition from #4890 D8 holds: an unsubscribed fleet keeps `fleet_logistics` and
   `inventory_transfers` entirely and loses only the contracts endpoints. The free tier stays whole.

### Phase 12 — Tests
Per phase. The email match against a confirmed account and **not** an unconfirmed one. The key matched
case-folded and separator-stripped, not matched across users, and taking precedence over a conflicting
email. A Ko-fi webhook test with a bad token, a replayed `kofi_transaction_id`, and a donor message with
no key. The partial unique index asserted as `RecordNotUnique`, not as a validation. `active_on` across
the open, closed, future and same-day boundaries. A reconciliation test that a manual subscription
survives a sync that would otherwise close it. A query-count assertion over a full feature listing per
D10. An integration test that an unsubscribed fleet's inventories, ledger and transfers are untouched
while its contracts answer `subscription_required`.

## Intent Verification

- [ ] **A subscribed fleet's members get the feature** — no personal gate on any of them, nobody else
      paying anything.
- [ ] **Nothing but a subscription grants it** — no Flipper gate, admin toggle or self-service switch
      opens a premium feature.
- [ ] **A lapse closes access** — with no job run, no column written and no deploy.
- [ ] **A comp survives a sync** — a manual subscription is untouched by an import that knows nothing
      about it.
- [ ] **Revocation is expressible** — ending a subscription removes access, and the row says who ended
      it and when.
- [ ] **Below the amount is not a subscription** — a nominated contribution under the figure opens
      nothing.
- [ ] **The free tier stays whole** — an unsubscribed fleet keeps inventories, the ledger and
      transfers, and loses only contracts.
- [ ] **A Patreon patron is linked without doing anything** — a confirmed email matching theirs links
      on the next sync, and an unconfirmed account never matches.
- [ ] **A Ko-fi donor is linked by their own message** — the key in `message` resolves to their account
      with no manual step.
- [ ] **A key cannot claim someone else's payment** — a key belongs to one account and matches only it.
- [ ] **The webhook is not a hole** — a bad token is refused, a replay creates nothing, and the
      response discloses nothing.
- [ ] **A fleet is told it lapsed** — admins are notified before anyone meets a 403.
- [ ] **A refusal reads as a price** — premium answers `subscription_required`; every other gate still
      answers `forbidden`.
- [ ] **The listing does not regress** — a full feature listing issues no more queries than before.
- [ ] **Every locale has the strings** — all seven, by hand, `%{}` placeholders.
- [ ] **The public API did not break** — `oasdiff` clean on all three schemas, with the schema and
      asyncapi documents regenerating byte-identical.

## Key files

| File | Role |
|------|------|
| `app/lib/patreon/client.rb` | `MEMBER_FIELDS` (`:8`) — gains `email`; `find_user` (`:76`) already resolves the included user record |
| `app/lib/patreon/supporter_importer.rb` | `assign_defaults` (`:76`) — never sets `user_id`; the whole gap in one method |
| `app/models/supporter_contribution.rb` | `active_now` / `active_in` (`:77`); the `source` enum (`:67`) Ko-fi joins; the `has_paper_trail` `only:` list D7 joins |
| `app/models/user.rb` | `supporter?` (`:493`) and its "gate perks on this one" comment; `calendar_feed_token`, the precedent for D5's key column |
| `app/models/fleet.rb` | `features` (`:231`) — the per-flag loop D10 must not land inside |
| `app/controllers/concerns/inventory_transfers_feature_concern.rb` | The concern shape D9 mirrors, and the composition rule Phase 11 preserves |
| `app/controllers/api/base_controller.rb` | `feature_enabled?` (`:72`) — stays exactly as it is, per D1 |
| `config/initializers/flipper.rb` | `testers` / `admins` (`:6`, `:10`) — and the groups this plan deliberately does **not** add |
| `config/feature_flags.yml` | The registry `pre-deploy` prunes; D1's first reason |
| `app/lib/versioned_item.rb` | `ROOTS` (`:27`) — where `FleetSubscription` registers |
| `app/models/notification.rb` | `notification_type` (`:39`) and `TYPES` (`:72`) |
| `app/models/admin_user.rb` | `community: %w[fleets users supporters]` (`:60`) — the section Phase 8 extends |
| `config/initializers/rack_attack.rb` | The throttle precedent D6's endpoint follows |
| `app/frontend/frontend/components/SupportBtn/Modal/index.vue` | The four funding links — and the four different answers D4–D6 give them |

## Not in scope (deferred)

- **Flipper as the entitlement layer.** D1, recorded here because it was the first design and the
  reasons it was dropped are the reasons not to reach for it again.
- **Patreon OAuth as a seventh provider.** The D4 email match covers Patreon automatically. An OAuth
  provider would add credentials, a callback and a maintained strategy to solve a solved problem, and
  would do nothing for the other three platforms.
- **PayPal and Buy Me a Coffee endpoints.** D6. Hand-entered with the key pasted from the payment note,
  which is the same resolution path and no new code, until either grows enough to argue otherwise.
- **Taking payment in the app.** Patreon and Ko-fi are the subscription systems. Stripe means invoices,
  tax, dunning, refunds and a webhook surface, none of it needed to grant a feature to a fleet that
  already pays.
- **Tiers and named plans.** D3. The extension is one nullable column plus a join. Ko-fi's `tier_name`
  is deliberately stored and ignored, so the data is there when it is wanted.
- **Per-seat pricing.** A subscription covers the fleet; counting members makes the price move when the
  roster does.
- **Making any shipped feature premium.** Contracts is unreleased, so nobody loses anything. With
  13,902 fleets against 3 supporters, paywalling something shipped would switch a working feature off
  for effectively the entire userbase.
- **Proration, refunds and grace periods.** D10's live read has no concept of a partial period.
- **An upsell anywhere but the refusal.** No banners, no locked-feature teasers in the fleet nav.

## Discovery Log

- **2026-09-14** Research and plan creation. Five things the research established that the idea as
  posed did not assume:

  **The blocker is identity, not entitlement.** 0 of 16 contributions have ever been linked to a user,
  so `supporter?` is false for all 59,946 accounts. Everything else here is small; this is not.

  **A claim key cannot work on Patreon.** `note` is *"The creator's notes on the member"* and there is
  no pledge message or survey field on the Member resource, so a key in a Patreon pledge message is
  invisible to the API. The key belongs to the platforms that carry a donor message, which is why D4
  and D5 split by platform instead of picking one mechanism.

  **Patreon's `email` field closes that gap on its own** — and safely, because both sides are
  independently verified rather than asserted. It needs a token scope the current one probably lacks,
  and the failure mode is indistinguishable from no match.

  **Ko-fi's webhook carries everything the key needs.** `message`, `email`, `amount`,
  `is_subscription_payment` and a transaction id, so Ko-fi is fully automatic rather than the
  hand-entered case it looked like at the start.

  **Flipper was the first design and is the wrong one.** The gate calls do already OR a fleet actor —
  verified against the dev database, with the flag on a fleet actor only,
  `Flipper.enabled?(flag, user, fleet)` returns true — so it would have worked. It was dropped for the
  four reasons in D1, of which deploy-time gate pruning is the one that would have caused an incident.

## Progress
- [ ] Phase 1 — Patreon identity
- [ ] Phase 2 — The claim key
- [ ] Phase 3 — Ko-fi
- [ ] Phase 4 — Nomination
- [ ] Phase 5 — The subscription record
- [ ] Phase 6 — Reconciliation
- [ ] Phase 7 — Enforcement
- [ ] Phase 8 — Admin
- [ ] Phase 9 — API and frontend
- [ ] Phase 10 — Notifications
- [ ] Phase 11 — Contracts as the first premium feature
- [ ] Phase 12 — Tests
