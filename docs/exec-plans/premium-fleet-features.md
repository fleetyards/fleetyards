# Premium fleet features — a subscription a fleet buys, held in its own record

## Goal

A fleet subscribes, and the premium features switch on for every member without any of them paying
individually or toggling anything. The entitlement is a first-class record with a period and an audit
trail — not a feature flag — so it can be granted, revoked, comped, and answered for.

Four fleet capabilities go behind it: **contracts** (#4890), **events**, **logistics** and **tours**
(#4912, behind a new `fleet_tours` flag).

Payment stays where it is — Patreon and Ko-fi — and the record is deliberately payment-agnostic, because
donations are not a lawful basis for selling software indefinitely (D15).

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

**None of the four capabilities is generally available.** An anonymous `GET /v1/features` against
production returns every globally-on flag:

```
tools_cargo_grids, tools_travel_times, fleet_starmap, fleet_worldmap,
discord_commands, discord_fleet_commands, oauth-{discord,google,github,twitch,citizenid,applications}
```

`fleet_logistics`, `fleet_mission_builder` and `tour_payouts` are absent, and `fleet_contracts` is not
deployed at all. So this is not a paywall going up around a shipped feature — it is four features
choosing a price before release, which is the one moment when that choice costs nobody anything. The
probe only reveals boolean gates, so individual fleets may still hold actor gates from early access;
D13 is about them.

Money arrives through four links in `SupportBtn/Modal` — Patreon, PayPal, Ko-fi and Buy Me a Coffee —
and they do not resemble each other. Patreon has an API the importer already uses. Ko-fi has a webhook.
PayPal and Buy Me a Coffee have neither. Identity therefore has more than one mechanism, and D5–D7
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
- **Alignment is not a reason.** D3 tidies the registry until each capability *is* one flag, which
  removes the shape objection and none of the four above. A subscription that happened to look like a
  flag would still prune, still only grant, still not audit, and still be toggled from a rollout page.

So the two questions stay separate and both must pass:

| question | answered by | on failure |
|---|---|---|
| Is this feature rolled out here? | Flipper, unchanged | `forbidden` — "not available" |
| Has this fleet bought it? | `FleetSubscription` | `subscription_required` — an upsell |

Flipper never learns the word premium; the entitlement layer never learns about rollout. Every flag
involved keeps doing exactly what a flag is for.

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

`source: manual` is not an afterthought — it is how a partner org gets comped, how D13's early-access
fleets keep what they have, how a support ticket is answered, and how a PayPal or Buy Me a Coffee
supporter is honoured at all.

The `source` enum is also the extension point D15 needs: the entitlement record deliberately says
nothing about how the money arrived, so a real billing provider later is another value here rather than
a second entitlement system.

### D3 — The flags get cleaned up first, so each has one owner

Two of the four capabilities do not currently correspond to a flag, and paywalling the flag as it
stands would charge for a personal feature. Both are fixed by tidying the registry rather than by
working around it:

| capability | flag | today | after |
|---|---|---|---|
| contracts | `fleet_contracts` | the flag is the feature | unchanged |
| events | `fleet_mission_builder` | the flag is the feature | unchanged |
| logistics | `fleet_logistics` | the flag is the feature | unchanged |
| tours | — | `tour_payouts` is *"one flag, two surfaces"* by its own registry comment | **new `fleet_tours` flag** for the fleet-scoped surfaces |

`inventory_transfers` is not part of this. It is an addon for logistics that composes on top of three
gates rather than replacing any of them, and it goes globally on once it reaches live — so it never
becomes a pricing unit, and nothing here touches it. A transfer into a fleet inventory still needs
`fleet_logistics`, which is what puts the fleet side behind the subscription for free.

`fleet_tours` covers a fleet's own tours from #4912 **and** the payout ledger on a fleet event, leaving
`tour_payouts` as purely the standalone tool under `/tools/`. That is what "one owner per flag" means
here: every fleet-scoped payout surface behind the new flag, every personal one behind the old. The
alternative — leaving the event ledger on `tour_payouts` — keeps a fleet surface and a personal surface
sharing a flag, which is the exact smell this cleanup exists to remove.

Stated plainly, because it is the part most easily lost later: **global tours and hangar inventories
are not affected by this.** A standalone tour under `/tools/tours/` and a member's own hangar or ship
inventory are personal features, they are free today, and they stay free — the subscription buys the
fleet-scoped surfaces and nothing else.

After the cleanup all four capabilities map one-to-one onto four flags. That is a convenience, not a
licence to move entitlement back into Flipper: every reason in D1 is unchanged by it, and alignment is
a fact about today rather than a property anything should depend on. `Subscriptions::PREMIUM_FEATURES`
stays a frozen list of capability keys — `%i[contracts events logistics tours]` — and enforcement stays
a `before_action` on the fleet-scoped controllers (D10), which is what keeps this true the next time a
flag and a surface diverge.

### D4 — Four capabilities, one flat tier

A fleet is subscribed or it is not, and a subscription covers all four capabilities. No plan column, no
plan table, no per-capability pricing.

Four is also the argument *for* a flat tier rather than against it: splitting them into tiers means
deciding which of contracts, events, logistics and tours is worth less than the others, before a single
fleet has paid for any of them. A second tier later is one nullable column plus a join — cheap
precisely because nothing today reads a plan it would have to start honouring.

The qualifying amount is a single configured figure in EUR cents. `SupporterImporter#apply_amount`
already normalises USD to EUR through `ExchangeRateFetcher` and stores both figures, so the comparison
needs no conversion at read time.

What stays free for every fleet: the fleet page and roster, roles and privileges, vehicles and the
fleetchart, stats, the starmap and worldmap, invites, alliances, and the Discord integration. The free
tier is still most of what a fleet does.

### D5 — Every platform gives us an email, so the linker is source-agnostic

All four funding routes carry the payer's email address, and it is the same resolution rule every time:
match it against the account whose **confirmed** email equals it.

| platform | where the email comes from |
|---|---|
| Patreon | the `email` field, under the `campaigns.members[email]` scope |
| Ko-fi | `email` on the webhook payload |
| PayPal | the payer address on the transaction, entered with the contribution |
| Buy Me a Coffee | the same, entered with the contribution |

So `supporter_contributions` gains a **`payer_email`** column, written by every path, and
`Supporters::Linker` takes a contribution rather than a platform. One rule, one place, four sources —
and the hand-entered platforms get the automatic match without an integration, because a human typing
the address into admin produces the identical input to a webhook supplying it.

Storing it rather than resolving and discarding buys the case that otherwise loses people silently: a
donor whose email has **no account yet**, who signs up with the same address a week later. The linker
re-runs and resolves them. Without the column that contribution is unlinkable forever, and nobody ever
finds out.

The match is safe in a way a user-entered email is not: neither side is a claim. The platform verified
the address for billing, Fleetyards verified it at confirmation, and the comparison is between two
independently verified records with no user assertion in between. An unconfirmed account never matches.

`payer_email` is personal data with an obvious purpose, and at this scale plaintext is proportionate —
it is already visible in each platform's own dashboard. If the volume ever makes that uncomfortable,
the column only ever gets equality-matched, so a normalised digest would serve identically and retain
nothing readable.

### D5a — There is no key on Patreon

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

This is why the claim key (D6) is a **fallback rather than the mechanism**: it exists for the supporter
whose platform email differs from their Fleetyards one, which at three supporters may be nobody.

**The three who pay today do not need any of this.** Their Patreon names already resolve against the
user table: `Elfwyn` and `RikonGB` match a username exactly, and `Christopher Jackson` is a legal name
with no exact match. So they are linked by asking and then by an admin edit, once, before any of the
automatic paths exist.

A name match is offered in admin as a **candidate for confirmation and never as an automatic link**. It
is a coincidence-capable heuristic, and the cost of being wrong is handing a stranger's fleet an
entitlement. Three people is a conversation, not an algorithm.

### D6 — The claim key is for the platforms that carry a donor message

The email match in D5 resolves most people. The key is for the rest — a supporter whose platform email
is not the one on their Fleetyards account, which no automatic rule can bridge.

PayPal, Ko-fi and Buy Me a Coffee all let the payer write a message, and all of them show it to the
recipient. That is the field Patreon does not have, and it is where the key goes.

`users.claim_key`, generated lazily, unique, shown in settings beside the support links. Crockford
base32 in a `FY-XXXX-XXXX` shape — no ambiguous characters, ~40 bits, regenerable if it leaks. Matched
case-insensitively with separators stripped, so a supporter who types `fy7k2m9qxd` is still found.

The key is per **user**, not per fleet. A per-fleet key would name the fleet in the payment and could
then only be re-pointed by making another payment; a user key plus an in-app nomination (D8) re-points
instantly.

The key is introduced **with D13's announcement**, so it is in place before the next payment anybody
makes. What it cannot do is reach us through Patreon — a recurring pledge has no "next donation" to
attach a message to, and D5 is why no field carries it. A Patreon supporter links by email or by
asking; the key is for the platforms where the payer writes something we receive.

Email is the fallback on these platforms too, and the key takes precedence where both match — the key
is a deliberate act, the email is a coincidence.

### D7 — Ko-fi's webhook makes the key automatic; PayPal and Buy Me a Coffee stay hand-entered

Ko-fi posts a webhook per payment carrying `message` (the donor's own text), `email`, `amount`,
`currency`, `is_subscription_payment`, `tier_name`, `kofi_transaction_id` and a `verification_token`,
as form-encoded JSON under a single `data` field. Every input the key mechanism needs arrives without
anyone touching anything.

So Ko-fi gets a real endpoint: verify the token, upsert a `SupporterContribution` keyed on
`kofi_transaction_id`, resolve the key from `message`, fall back to email. `is_subscription_payment`
maps onto `recurring`, which the model already has.

PayPal and Buy Me a Coffee have no webhook worth building against for this, so their contributions stay
hand-entered — with the key pasted from the payment note, which is the same resolution path and no new
code.

The endpoint is public and unauthenticated by nature: constant-time token comparison, a throttle, and
no information in the response beyond acceptance.

### D8 — The supporter nominates the fleet in the app

A linked supporter picks which fleet their subscription covers, in settings.
`supporter_contributions` gains a nullable `fleet_id` for that nomination.

The derived alternative — *any accepted admin of the fleet is a supporter* — fails in both directions:
a supporter who admins five fleets would upgrade all five, and a fleet would lose its features when an
admin who was never the payer leaves. Sponsorship is a fact about the money, not about the roster.

One fleet per contribution. Someone covering two fleets has two contributions, which is also how they
would pay for two.

### D9 — The importers propose; the subscription record decides

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
contribution behind it is manual by construction and is left alone — which is what protects every
D13 comp.

### D10 — Enforcement is a `before_action`, beside the flag check and after it

```ruby
before_action :check_fleet_contracts_feature
before_action -> { require_fleet_subscription(:contracts) }
```

A concern, `FleetSubscriptionConcern`, mirroring `InventoryTransfersFeatureConcern` — the shape this
codebase already uses for exactly this job. One greppable line per controller, no policy branch, and no
service learning about money.

The order carries meaning. A feature that is not rolled out answers "not available" to everyone,
subscribed or not; only a feature that *is* rolled out and unbought answers with an upsell. Reversed, a
fleet would be sold something they could not yet have.

The capability argument is what makes D3 work: the same concern guards four different surfaces, and the
two that share a flag with a personal feature guard only their fleet-scoped controllers.

### D11 — Lapse is a read, not a job

No expiry sweep and no state column. `Fleet#subscribed?` is
`fleet_subscriptions.active_on(Date.current).exists?` — `started_at <= date AND (ended_at IS NULL OR
ended_at >= date)` — memoised per instance.

When D9 closes a subscription the next request stops granting; when it reopens one the next request
grants. The same argument #4890 D1 makes for contract progress: a thing computable from the record
should not also be stored where the two can disagree.

Memoisation is not a detail. `Fleet#features` and `Frontend::BaseController` iterate every flag in the
registry per request, and any entitlement read landing inside that loop multiplies by the flag count.
Asserted with a query-count test, not left to inspection.

### D12 — A refusal has to say it is a price, not a fault

Today an unavailable feature renders `{code: "forbidden", message: "This feature is not available"}`,
which for an unbought feature reads as broken and gives the frontend nothing to offer.

Premium refusals render `subscription_required`, which the frontend turns into a link to the support
page. The existing code is untouched for every non-premium gate.

"Price" here means *this is unbought*, not *here is a checkout*. Per D15 the copy describes a supporter
contribution that unlocks the feature for a nominated fleet, and the link goes to the support page —
never a shop.

Two constraints, neither optional: the code is a **literal** string at every site — an interpolated one
ships `translation missing` silently — and it needs an entry in all seven locale files by hand, because
there is no Crowdin and no CI check for locale parity.

### D13 — The transition is announced with a date, and beta access is graced rather than comped

The four capabilities are in beta behind Flipper actor gates. Those fleets tested unfinished work, and
the fair thing is not a permanent free ride — it is **knowing in advance**. So the mechanism is an
announcement naming a concrete date on which the features become supporter features, made far enough
ahead that nobody is surprised and everybody can decide.

That changes what the comping task is for. It is no longer a way to avoid cutting testers off forever;
it is a **grace window** that keeps them running past the date while they decide:

1. A one-off task reads Flipper and opens a `source: manual` subscription for every fleet holding an
   actor gate on any of the four flags, and for every fleet whose members hold one — D1's OR means a
   member's personal gate is what has been granting access.
2. Those subscriptions carry an `ended_at` **set to the end of the grace window**, not left open, and a
   note naming the announcement. They expire by themselves under D11's live read, with no second task
   and nothing to remember.

The window is **three months** from the announcement — ample at this scale, where the whole affected
population of paying supporters is three people and the claim key ships with the announcement itself. A permanent comp is the option to avoid: the fleets that tested hardest are the ones most
likely to subscribe, and comping them forever removes exactly that group.

It is a task rather than a migration because it reads Flipper, which a schema migration has no business
doing, and because it wants to be runnable again after the numbers are checked. `dry_run` defaults to
true, which for this codebase means a bare run reports and rolls back.

Graced subscriptions have no contribution behind them, so D9 leaves them alone.

### D14 — A fleet is told before it finds out from a 403

Losing features silently is the worst version of this. Two notification types, to the fleet's admins:
`fleet_subscription_started` and `fleet_subscription_ended`, the second carrying what lapsed and why.

No notification for a nomination change — that is the supporter's own action, in their own settings.

### D15 — Donations are not licence sales, and this will have to change

D13's announcement is also the honest version of "supporter perks may change": a dated, public notice
is what makes a later move to a billing provider a change people were told about rather than one they
discover. The wording is constrained by this decision — supporter features, never a purchase.


Patreon and Ko-fi are donation platforms. A payment that grants software features is consideration for
a supply rather than a gift, whatever the button says, and past a certain revenue that distinction
stops being academic under German law: Umsatzsteuer has to be charged and remitted, and customers need
real invoices carrying the mandatory contents of §14 UStG. The Kleinunternehmerregelung covers the
current scale; it will not cover an interesting one.

Two facts shape how much exposure there is today:

- **Patreon is merchant of record for EU memberships** and collects and remits VAT on the patron's
  side under the deemed-supplier rule for electronically supplied services. Ko-fi's platform products
  work similarly.
- **That coverage stops at the platform's edge.** A direct PayPal or Buy Me a Coffee payment is a
  supply from you to the customer with nothing in between, so it is the exposed path — and it is
  precisely the path D7 keeps hand-entered and small.

A merchant of record — Paddle, FastSpring, Lemon Squeezy — removes most of the tax half by becoming the
legal seller, and is the likely answer when this is real. It does not remove the rest: income taxes,
our own supply *to* the provider, the § 19 thresholds, and the consumer-facing obligations attaching to
an account and a cancellation flow that live here rather than at the checkout. And it fixes nothing at
all while donations still grant the same entitlement beside it — that is a compliant channel next to a
non-compliant one. The end state is a provider selling premium and donations granting only the badge.

None of that is built now, and this plan does not build it. What it does is refuse to make it harder:
the entitlement is a record with a period and a source (D2), decoupled from payment entirely (D1), so
an invoiced billing provider arrives as a new `source` value and a new reconciler beside
`Subscriptions::Sync`. Nothing in D10's enforcement, D11's read or the four capabilities changes.

One thing is in scope now, because it is free and cannot be retrofitted: **the copy must not describe a
purchase.** No price list, no checkout, no "buy", no "licence" — a supporter contribution that unlocks
fleet features for the fleet they nominate. D12's refusal links to the support page, it does not open a
shop. Getting this wrong is a legal-form problem that a later migration cannot undo, because it is what
the customer was told they were doing.

Starting on donations and migrating later is the intended sequence, and it holds for a structural
reason rather than a numerical one: **no paid contract is concluded with a consumer here.** Patreon is
merchant of record and Fleetyards recognises a membership, which keeps the consumer-law obligations —
the ones with no revenue threshold — with the platform. That is also what the copy constraint below
protects. The findings note lists the tripwires that should end the arrangement.

This is a description of the problem, not tax advice. Get a Steuerberater involved before the revenue
is worth arguing about, not after — and a Fachanwalt for the consumer-law half, which bites at the
first euro rather than at a threshold. The detail is in
[`docs/findings/selling-software-in-germany.md`](../findings/selling-software-in-germany.md).
### D16 — Nothing is enforced until entitlement is reachable, and that is measured

The announcement sets a date. The date is not the constraint — **being able to hold a subscription by
then is.** Zero of sixteen contributions carry a `user_id` today, so if identity and nomination are not
live and in use before the date, the cutover finds no subscriptions, and the features switch off for
every fleet including the three that pay.

So the order is fixed, and the announcement date is chosen to fit it rather than the reverse:

| | |
|---|---|
| **well before the date** | Phases 0–6 in production: flag cleanup, identity, the claim key, Ko-fi, nomination, the subscription record and reconciliation |
| **the announcement** | names the date, and the settings surfaces it points at already work |
| **the window** | supporters link and nominate; Phase 8 opens the graced subscriptions |
| **the date** | Phase 7 — enforcement — and nothing else |

Enforcement is therefore the **last** thing built and the last thing switched on, and it is gated on a
number rather than on a calendar: a readiness query reporting how many fleets currently reaching a
premium surface have neither a subscription nor a grace row. Flipping enforcement without having read
that number is how the three paying supporters lose access on announcement day.

## What changes

### Phase 0 — Flag cleanup (independent, lands first)
1. A `fleet_tours` flag in `config/feature_flags.yml` per D3, covering #4912's fleet-scoped tour routes
   and the payout ledger on a fleet event. `tour_payouts` keeps the standalone `/tools/` tool alone.
2. The gate calls on those surfaces move to the new flag. Lands with or immediately after #4912, and is
   a prerequisite for Phase 7 rather than part of it.
3. `inventory_transfers` is untouched — it is an addon that composes on three gates and goes globally
   on when it reaches live.

### Phase 1 — Identity by email
1. Migration: `payer_email` on `supporter_contributions`, indexed, per D5.
2. `Supporters::Linker` — takes a contribution, matches `payer_email` against a **confirmed** account,
   idempotent and safe to re-run over unlinked rows.
3. `Patreon::Member` gains `email`; `MEMBER_FIELDS` gains it; the access token is reissued with
   `campaigns.members[email]`. A missing field is logged as a scope problem, distinctly from an
   unmatched patron.
4. The admin contribution form takes `payer_email`, so a hand-entered PayPal or Buy Me a Coffee payment
   resolves through the same path as a webhook.
5. A periodic re-run over unlinked contributions, for the donor who signs up after paying.

### Phase 2 — The claim key
1. Migration: `claim_key` on `users`, unique, nullable — generated on first view, the way
   `calendar_feed_token` already is.
2. `Users::ClaimKey` — generation over the Crockford alphabet, and the normalising match.
3. `Supporters::Linker` gains the key arm, taking precedence over email per D6.
4. Settings shows the key, what to paste it into, and a regenerate action.

### Phase 3 — Ko-fi
1. A webhook endpoint per D7: constant-time `verification_token` check, throttle, form-encoded `data`.
2. `Kofi::PaymentImporter` — upsert on `kofi_transaction_id`, `is_subscription_payment` → `recurring`,
   `email` into `payer_email`, then resolve through `Supporters::Linker`.
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
3. `Fleet#subscribed?` / `#active_subscription`, memoised per D11.
4. `Subscriptions::PREMIUM_FEATURES` and the qualifying amount, in one place.

### Phase 6 — Reconciliation
1. `Subscriptions::Sync` per D9, run after `PatreonSupporterSyncJob`, after a Ko-fi payment, and on a
   nomination change.
2. Manual subscriptions excluded by construction — asserted, not assumed.

### Phase 7 — Enforcement *(built last, switched on at the announced date)*
1. `FleetSubscriptionConcern` with `require_fleet_subscription(capability)`, rendering
   `subscription_required`.
2. Applied per D3, after the flag check per D10:
   - **contracts** — the contracts controllers from #4890.
   - **events** — the fleet event, signup, ship, team, slot and admin controllers.
   - **logistics** — the fleet inventory, item, stock and transfer controllers. `inventory_transfers`
     is not touched, and the personal hangar and ship inventory controllers are not touched.
   - **tours** — the surfaces behind Phase 0's `fleet_tours`. `/tools/tours/` and the slug-addressed
     settle, cancel and invite paths stay free.

### Phase 8 — The announcement, and grace for beta access
1. A readiness query per D16: fleets reaching a premium surface today with neither a subscription nor a
   grace row. Reported before anything is switched, and again before the date.
2. A maintenance task per D13, `dry_run` defaulting to true, reading Flipper actor gates on the four
   flags and opening `source: manual` subscriptions whose `ended_at` is the end of the grace window.
3. The announcement itself. Nothing in the app broadcasts, so it is: a notification to the admins of
   every affected fleet and to every gate-holding member, the Discord channels, and a dismissible
   notice on the fleet pages concerned. A blog or changelog surface does not exist and is not built
   for this.
4. Copy reviewed against D15 — supporter features, a date, and what happens to a fleet that does not
   subscribe. No price, no checkout, no "buy".

### Phase 9 — Admin
1. Subscriptions CRUD under the existing `community` section beside `supporters`: open, close, comp,
   with a reason recorded through the paper trail.
2. The contribution list shows its nominated fleet, its resolved user, and whether a subscription was
   seeded from it.

### Phase 10 — API and frontend
1. Subscription status on the fleet payload; the four capabilities exposed so the UI can mark what a
   subscription would unlock.
2. The upsell on `subscription_required`, the settings surfaces from Phases 2 and 4, and every string
   in all seven locales with `%{}` placeholders — this is i18n-js, not vue-i18n.
3. The fleet nav hides a premium surface the fleet has not bought rather than linking to a refusal.
4. `./bin/generate-schema` after a server restart, then orval for both clients, then `oasdiff`.

### Phase 11 — Notifications
Two types per D14, their `TYPES` entries, retention and preference defaults, and seven locales.

### Phase 12 — Tests
Per phase. The email match against a confirmed account and **not** an unconfirmed one. The key matched
case-folded and separator-stripped, not matched across users, and taking precedence over a conflicting
email. A Ko-fi webhook test with a bad token, a replayed `kofi_transaction_id`, and a donor message with
no key. The partial unique index asserted as `RecordNotUnique`, not as a validation. `active_on` across
the open, closed, future and same-day boundaries. A reconciliation test that a manual subscription
survives a sync that would otherwise close it, and a comping-task test over dry and wet runs.

**The D3 split gets its own tests, because it is the decision most easily broken later:** an
unsubscribed fleet's members can still transfer between their own hangar and ship inventories, and can
still create, read and settle a standalone `/tools/` tour. A query-count assertion over a full feature
listing per D11. An integration test that an unsubscribed fleet's roster, roles, vehicles, stats,
starmap, worldmap and alliances are untouched while all four premium surfaces answer
`subscription_required`.

## Intent Verification

- [ ] **A subscribed fleet's members get all four** — no personal gate on any of them, nobody else
      paying anything.
- [ ] **Nothing but a subscription grants them** — no Flipper gate, admin toggle or self-service switch
      opens a premium surface.
- [ ] **Personal features are still free** — an unsubscribed fleet's members transfer between their own
      hangar and ship inventories, and run a standalone tour, exactly as before.
- [ ] **`inventory_transfers` was not touched** — its gates, its composition rule and its personal
      surfaces are byte-for-byte what they were.
- [ ] **Each capability owns one flag** — after Phase 0, no premium surface shares a flag with a free
      one, and `tour_payouts` gates only the standalone tool.
- [ ] **Nothing reads as a shop** — no price, no checkout, no "buy" and no "licence" in any locale; the
      refusal and the nav point at the support page.
- [ ] **Nobody is surprised** — the announcement named a date, reached the admins of every affected
      fleet, and went out before any enforcement shipped.
- [ ] **Beta access ran past the date** — every fleet holding an actor gate has a grace subscription
      covering the announced window, and it expires on its own without a second task.
- [ ] **The three who pay did not lose access** — the readiness query was read before enforcement was
      switched on, and reported no linked supporter without a subscription.
- [ ] **A comp survives a sync** — a manual subscription is untouched by an import that knows nothing
      about it.
- [ ] **A lapse closes access** — with no job run, no column written and no deploy.
- [ ] **Revocation is expressible** — ending a subscription removes access, and the row says who ended
      it and when.
- [ ] **Below the amount is not a subscription** — a nominated contribution under the figure opens
      nothing.
- [ ] **The free tier is still a fleet** — roster, roles, vehicles, fleetchart, stats, starmap,
      worldmap, invites, alliances and Discord all work unsubscribed.
- [ ] **Every platform links by email** — Patreon, Ko-fi and a hand-entered PayPal payment all resolve
      through the one linker, and an unconfirmed account never matches on any of them.
- [ ] **A late signup is still found** — a donor whose email had no account when they paid is linked
      when they register, without anyone re-entering anything.
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
| `config/feature_flags.yml` | The two comments D3 turns on: `tour_payouts` *"one flag, two surfaces"*, and `inventory_transfers` riding on top of three gates |
| `app/lib/patreon/client.rb` | `MEMBER_FIELDS` (`:8`) — gains `email`; `find_user` (`:76`) already resolves the included user record |
| `app/lib/patreon/supporter_importer.rb` | `assign_defaults` (`:76`) — never sets `user_id`; the whole gap in one method |
| `app/models/supporter_contribution.rb` | `active_now` / `active_in` (`:77`); the `source` enum (`:67`) Ko-fi joins; the `has_paper_trail` `only:` list D8 joins |
| `app/models/user.rb` | `supporter?` (`:493`) and its "gate perks on this one" comment; `calendar_feed_token`, the precedent for D6's key column |
| `app/models/fleet.rb` | `features` (`:231`) — the per-flag loop D11 must not land inside |
| `app/controllers/concerns/inventory_transfers_feature_concern.rb` | The concern shape D10 mirrors, and the composition rule D3 preserves by leaving it alone |
| `app/controllers/api/v1/fleet_inventory_transfers_controller.rb` | `check_fleet_logistics_feature` (`:36`) — the fleet side of the split |
| `app/controllers/api/base_controller.rb` | `feature_enabled?` (`:72`) — stays exactly as it is, per D1 |
| `config/initializers/flipper.rb` | `testers` / `admins` (`:6`, `:10`) — and the groups this plan deliberately does **not** add |
| `app/lib/versioned_item.rb` | `ROOTS` (`:27`) — where `FleetSubscription` registers |
| `app/models/notification.rb` | `notification_type` (`:39`) and `TYPES` (`:72`) |
| `app/models/admin_user.rb` | `community: %w[fleets users supporters]` (`:60`) — the section Phase 9 extends |
| `config/initializers/rack_attack.rb` | The throttle precedent D7's endpoint follows |
| `app/frontend/frontend/components/SupportBtn/Modal/index.vue` | The four funding links — and the four different answers D5–D7 give them |

## Not in scope (deferred)

- **Flipper as the entitlement layer.** D1 and D3, recorded here because it was the first design and
  the reasons it was dropped are the reasons not to reach for it again.
- **A user-entered "my Patreon email" field.** Still out, and permanently. An address somebody types is
  an assertion, and it would let anyone claim a stranger's contribution — and, once this plan lands,
  their entitlement. What makes the D5 email match safe is that neither side is asserted: the platform
  verified the address for billing, Fleetyards verified it at confirmation. Patreon OAuth (#4917) is
  what closed this gap instead, and it is no longer deferred — see the Discovery Log.
- **PayPal and Buy Me a Coffee endpoints.** D7. Hand-entered with the key pasted from the payment note,
  which is the same resolution path and no new code, until either grows enough to argue otherwise.
- **Taking payment in the app, and everything the tax authority will eventually want.** Patreon and
  Ko-fi are the subscription systems for now. Real billing means a merchant of record, Umsatzsteuer,
  §14 UStG invoices, OSS registration for EU B2C, reverse charge for B2B, and retention — a project of
  its own, and per D15 one this plan is shaped to accept later rather than to pre-empt now.
- **Tiers and named plans.** D4. The extension is one nullable column plus a join. Ko-fi's `tier_name`
  is deliberately stored and ignored, so the data is there when it is wanted.
- **Per-seat pricing.** A subscription covers the fleet; counting members makes the price move when the
  roster does.
- **Paywalling `fleet_allies`, the starmap or the worldmap.** The first is days old and the other two
  are the only fleet flags already boolean-on in production — taking them back is the one move here
  that would cost a fleet something it has.
- **Renaming `tour_payouts`.** Once D3 moves the fleet surfaces to `fleet_tours`, the old name
  describes a personal tool and reads oddly. A rename is a rollout change and can wait for one.
- **Proration, refunds and grace periods.** D11's live read has no concept of a partial period.
- **An upsell anywhere but the refusal and the nav.** No banners, no locked-feature teasers.

## Discovery Log

- **2026-09-14** Research and plan creation. Seven things the research established that the idea as
  posed did not assume:

  **Enforcement is the last thing switched on, and it is gated on a number.** An announced date makes
  the transition fair, but entitlement has to be *reachable* by then: with 0 of 16 contributions
  linked, switching enforcement on before identity and nomination are in use would take the features
  from every fleet, the paying supporters included. D16 fixes the order and requires a readiness query
  to be read rather than assumed.

  **The blocker is identity, not entitlement.** 0 of 16 contributions have ever been linked to a user,
  so `supporter?` is false for all 59,946 accounts. Everything else here is small; this is not.

  **Nothing being paywalled is released.** An anonymous production `GET /v1/features` lists every
  boolean-on flag, and none of the four is among them. This is four features choosing a price before
  release rather than a paywall going up around a shipped one — which is what makes D13 a small task
  instead of a migration with a communications plan attached.

  **Two of the four are not a whole flag.** `tour_payouts` is *"one flag, two surfaces"* by its own
  registry comment and `inventory_transfers` covers hangar and ship transfers, so paywalling either
  flag would charge for a personal feature. D3 is the result, and it is also the thing a Flipper group
  could not have expressed at any price.

  **A claim key cannot work on Patreon.** `note` is *"The creator's notes on the member"* and there is
  no pledge message or survey field on the Member resource. The key belongs to the platforms that carry
  a donor message, which is why D5 and D6 split by platform instead of picking one mechanism.

  **Ko-fi's webhook carries everything the key needs.** `message`, `email`, `amount`,
  `is_subscription_payment` and a transaction id, so Ko-fi is fully automatic rather than the
  hand-entered case it looked like at the start.

  **Two of the four were not a whole flag, and the answer was to tidy rather than route around.**
  `tour_payouts` is *"one flag, two surfaces"* by its own registry comment; `inventory_transfers` is an
  addon that composes on three gates and will be globally on. A new `fleet_tours` flag fixes the first
  and the second needs nothing, which leaves all four capabilities aligned one-to-one with a flag —
  and, per D1, changes nothing about where entitlement lives.

  **The money has a legal form, and donations are not it.** Patreon is merchant of record for EU
  memberships and remits VAT under the deemed-supplier rule, but that coverage stops at the platform's
  edge, so direct PayPal and Buy Me a Coffee payments are the exposed path. D15 records what this will
  eventually need and what it costs now: nothing structural, and one constraint on the copy that cannot
  be retrofitted.

  **Flipper was the first design and is the wrong one.** The gate calls do already OR a fleet actor —
  verified against the dev database, with the flag on a fleet actor only,
  `Flipper.enabled?(flag, user, fleet)` returns true — so it would have worked for contracts alone. It
  was dropped for the four reasons in D1, and then D3 made it impossible rather than merely unwise.

- **2026-09-16** Phases 0–3 in production, and one deferral closed early.

  **The identity half is done.** `payer_email` and `Supporters::Linker` (#4915), the claim key and the
  `/support` page (#4949, #4950), the Ko-fi webhook and `Kofi::PaymentImporter`, and `linked_via`
  recording which rule made each link. `fleet_tours` is in the registry, so Phase 0's cleanup holds and
  all four capabilities map one-to-one onto a flag.

  **Patreon OAuth shipped (#4917), ahead of this plan rather than after it.** It was written up above
  as a wanted follow-up, on the reasoning that a patron whose Patreon address is not their Fleetyards
  one had no self-service path. That patron now has one, which removes the largest hole D5a left open
  and makes the claim key the fallback it was always meant to be. The deferral it replaced — a
  user-entered "my Patreon email" field — stays out permanently, for the reason it was always out: an
  address somebody types is an assertion.

  **Nothing is enforced, and nothing grants.** No `fleet_subscriptions` table, no `Subscriptions::`
  namespace, no `fleet_id` on a contribution. D16's order is intact: the entitlement half is #4959, and
  enforcement is still last and still gated on the readiness query rather than on a date.

## Progress

Phases 0–3 are shipped: the identity half — who paid — is answered. The entitlement half is tracked
in #4959, and the phase order is fixed by D16 rather than by preference.

- [x] Phase 0 — Flag cleanup (independent, lands first)
- [x] Phase 1 — Identity by email (#4915, #4949)
- [x] Phase 2 — The claim key (#4949, #4950)
- [x] Phase 3 — Ko-fi
- [ ] Phase 4 — Nomination (#4952)
- [ ] Phase 5 — The subscription record (#4953)
- [ ] Phase 6 — Reconciliation (#4954)
- [ ] Phase 7 — Enforcement (#4957)
- [ ] Phase 8 — The announcement, and grace for beta access (#4958)
- [ ] Phase 9 — Admin (#4955)
- [ ] Phase 10 — API and frontend (#4957)
- [ ] Phase 11 — Notifications (#4956)
- [ ] Phase 12 — Tests (per phase, not a phase of its own)
