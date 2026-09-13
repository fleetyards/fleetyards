# Friends for users, allies for fleets

## Goal

A user can befriend another user and a fleet can ally with another fleet, each by a request the other side accepts, declines or ignores — and the relationship opens a hangar, a wishlist, a fleet's ships, its stats and its members to people who are not the public, and makes both sides a transfer party without a fleet in common.

## Context

#4878 gave every party a stance on who may send it goods: `everyone`, `known`, `nobody` (`InventoryTransferParty::POLICIES`). `known` has exactly one meaning, and `TransferGate#shares_a_fleet?` (`app/services/inventories/transfer_gate.rb:113`) is the whole of it — a fleet in common for two users, membership for a user and a fleet. That is the only relationship this platform can express.

Everything else is a binary published to the world or to nobody. `public_hangar` (default `true`), `public_hangar_stats`, `public_wishlist`, `public_fleet` (default `false`), `public_fleet_stats` — five booleans, and between "anyone with the URL" and "closed" there is nothing. The person who turned their hangar off did so because of the internet, not because of the four people they fly with, and there is currently no way to say so.

Two relationships close that gap. Both are symmetric, both are agreed to rather than declared, and both already have their extension point cut for them: the picker that chooses who a transfer is addressed to says so in as many words —

> This list is the grouping, and it is the extension point: a friends list, or any other way of knowing somebody, becomes another entry here rather than another branch in the modal.
> — `app/frontend/frontend/composables/useTransferTargets.ts`

| | between | held by | managed by |
|---|---|---|---|
| **Friendship** | user ↔ user | both users | each user, for themselves |
| **Alliance** | fleet ↔ fleet | both fleets | each fleet's admins |

Resolves #4887

Stacked on `feat/4878-inventory-transfers` (#4881). The visibility half stands alone; the transfer half names classes that exist only on that branch.

## Decisions

### D1 — Two tables, not one polymorphic one

A friendship is always user↔user and an alliance is always fleet↔fleet. There is no user↔fleet relationship in this feature — that is what membership already is. So the thing pointed at is consistently one type on both ends, which is the case #4855 D3 answered with two tables, and the opposite of the case #4878 D4 and D10 answered with four nullable foreign keys.

```
friendships                       fleet_alliances
  requester_id  → users             requester_fleet_id → fleets
  addressee_id  → users             addressee_fleet_id → fleets
```

Four real foreign keys, no check constraints needed to say which pair is populated, and `ON DELETE CASCADE` on all of them — a relationship with a deleted account is not evidence of anything and there are no goods behind it, the same argument #4878 D10 made for transfer rules and the opposite of the `RESTRICT` its transfers needed.

What the two *do* share is the handshake, and that goes in a concern — `PartyRelationship` — which owns the state machine, the answer events, the unordered-pair rules and the cap. This is the shape the inventory subsystem already uses for its two parallel stacks (`InventoryStock`, `InventoryLedgerEntry`, `StockPosition`): two tables, one set of behaviour, stated once.

### D2 — One row per pair, and the pair is unordered

The alternative is two mirrored rows, which makes "who are my friends" a plain index scan on one column. It also doubles every write, gives one relationship two states that can disagree, and makes the state machine own a row it did not transition.

One row. `requester` and `addressee` record who asked, which the UI needs anyway to label an incoming request, but they carry no authority once the row is `accepted`: either side may end it, and every read is over both columns.

Uniqueness is per **unordered** pair, enforced in the database:

```sql
CREATE UNIQUE INDEX index_friendships_on_pair
  ON friendships (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id));
```

`LEAST`/`GREATEST` are immutable over `uuid`, so the expression is indexable. Without it, A requesting B and B requesting A produce two rows for one relationship and the second acceptance has nothing to do. With it, the second request fails on a unique violation — which is the wrong answer, so see D4.

Reads are `WHERE (requester_id = ? OR addressee_id = ?) AND aasm_state = 'accepted'`, served by two single-column indexes and a BitmapOr. That is the cost of the one-row shape and it is the right trade at this scale; a materialised mirror is what to reach for if a friend list ever gets long enough to matter, and nothing about this schema forecloses it.

A check constraint forbids `requester_id = addressee_id`. You are not your own friend, and a fleet is not its own ally.

### D3 — Ignore is invisible, and that is the entire point

Three answers, and the third is the one worth designing:

| answer | the recipient's inbox | what the requester sees | can they ask again? |
|---|---|---|---|
| **accept** | gone | accepted | — |
| **decline** | gone | declined | yes |
| **ignore** | gone | **pending, unchanged** | yes, and it goes nowhere |

An ignore that the requester can detect is a decline with extra steps and worse manners. So `ignored` is a real state that renders to the requester exactly as `pending` does, and a further request from the same sender is **absorbed** by the ignored row: the API answers as though it were sent, the row does not move, and nothing reaches the recipient.

That absorption is what makes this feature need no block list. A per-relationship, permanent, silent refusal is precisely what blocking is for here, and it costs one state rather than a table. A block that covers more than requests — the platform-wide kind — is not asked for and is not built (see *Not in scope*).

The recipient can still change their mind: ignored rows stay readable under a filter and can be accepted later. They are hidden, not deleted.

### D4 — A crossing request is an acceptance

A asks B. Before B answers, B asks A. The unique index in D2 would fail B's request with a database error about a row B cannot see, which is both a bad error and a small information leak.

So a request that finds an existing `pending` row addressed to the sender **accepts it** instead of creating one. The two people agreed; the order they clicked in is not a thing the system should have an opinion about.

The same request finding an `ignored` row is absorbed per D3 — it must not become an acceptance, or ignoring someone would be undone by them asking again, which is the exact behaviour ignore exists to prevent. Finding a `declined` row reopens it as a fresh `pending` request; declining is explicit and does not claim to be permanent.

### D5 — Nobody is told about a refusal

Two notification types per relationship, not four:

```
friend_request_received      → the addressee
friend_request_accepted      → the requester
fleet_ally_request_received  → the addressee fleet's ally managers
fleet_ally_request_accepted  → the requester fleet's ally managers
```

No decline notification, and obviously no ignore notification — an ignore that notifies is not an ignore. This is not a gap: `Notification::TYPES` has `fleet_invite`, `fleet_member_requested`, `fleet_member_accepted` and `fleet_request_accepted`, and has never had a declined counterpart for the identical flow (`app/models/notification.rb:46`). A refusal is visible in the requester's own sent list, which is where somebody who wants to know can look, and it does not arrive as a ping.

Both `_received` types get accept / decline call-to-actions, the way membership notifications already do.

### D6 — A relationship widens an audience; it never overrides a setting

Every surface keeps its own switch, and the relationship only ever moves it from *nobody* to *my friends* / *our allies*. Nothing here opens something its owner has not opened.

**Spelled as a second boolean, not as an enum.** `public_hangar` is a boolean in the public OpenAPI schema, on `/users/me`, and in the admin user payload. Turning it into a three-valued enum is a breaking schema change on a branch already stacked three deep, and `api-schema-breaking` effectively diffs the whole stack against `main`. So each surface gains a sibling:

| surface | today | added |
|---|---|---|
| hangar | `public_hangar` *(default true)* | `friends_hangar` |
| hangar stats | `public_hangar_stats` | `friends_hangar_stats` |
| wishlist | `public_wishlist` | `friends_wishlist` |
| fleet | `public_fleet` *(default false)* | `allies_fleet` |
| fleet stats | `public_fleet_stats` | `allies_fleet_stats` |
| fleet members | *(nothing — see D8)* | `allies_fleet_members` |

The rule is monotone and stated once: **public wins, and the friends flag is consulted only when public is off.** "Public on, friends off" is not a contradiction to resolve — a friend is a member of the public, and the second flag is simply not read. What that buys is that no existing value changes meaning and no existing client breaks.

It is two booleans spelling a three-valued enum, and that is the honest description of the trade. The consolidation is worth doing the next time this file is opened for a breaking release; it is not worth doing from inside a stack.

Defaults: every new flag is `false`. `public_hangar` already defaults to `true`, so for most accounts nothing changes at all — the new switch matters precisely to the people who turned the old one off, which is who asked for it.

### D7 — The widening happens in the policies, and in the three places that are not policies

`ApplicationPolicy` is `authorize :user, allow_nil: true`, and `Public::FleetPolicy` already consults it — `fleet_membership&.accepted? || record.public_fleet?` (`app/policies/public/fleet_policy.rb:5`). So the public policies are already not purely anonymous, and the widening is one clause each:

```ruby
# Public::UserPolicy
def show? = record.public_hangar? || (record.friends_hangar? && friend?)
```

Three call sites do **not** go through a policy, and each is its own small trap:

1. `Api::V1::Public::VehiclesController:13` and `:25` check `user.public_hangar?` inline, twice, on two different actions. Both move to the policy rather than growing a second clause.
2. `Api::V1::Public::HangarsController:42` is a bulk filter — `User.where(normalized_username: usernames, public_hangar: true)` — for the multi-hangar compare. Widening it is a join against friendships for the reader, not a boolean flip, and getting it wrong leaks a hangar into a comparison rather than onto a page.
3. `Public::FleetPolicy#show?` admits on `public_fleet? || public_fleet_stats?`, so a fleet that publishes only its stats is already readable by the show endpoint. The ally clause has to be added to both `show?` and `show_stats?` independently or `allies_fleet_stats` silently opens the fleet page too.

### D8 — An ally's view of the members is a different payload, not the same one with a policy in front

`app/views/api/v1/fleet_members/_base.jbuilder` renders, for each member: their Discord, YouTube, Twitch and Guilded handles, their RSI handle, their homepage, their latitude and longitude, their current system, and when they were last active. It is the payload the fleet's own officers read, and every field in it is there because a fleet manages its people.

Handing that to another organisation because two admins shook hands is not "showing the member list". So the ally view is a separate partial — `_allied_member.jbuilder` — carrying username, avatar, role name, and nothing else. Adding a field to it is a deliberate act; inheriting one is not possible.

Two further rules on top:

- **`hide_owner` hides you.** It is today the only per-user signal meaning "do not attach my name to this fleet's outward-facing data" — it is what `fleet_vehicles/_vehicle.jbuilder:9` already honours. A member with it set is counted in the fleet's totals and omitted from the ally's list by name.
- **Ships need no new rule at all.** `fleet.vehicles` reads through `FleetVehicle` rows that `FleetMembership#ships_filter` has already decided the contents of — a member who chose `hide` has no rows, and one who chose `hangar_group` has only some. An ally inherits every member's existing choice for free, and the plan's job is to *not break* that rather than to implement it.

### D9 — `known` gains two meanings, in one method, and grants nothing else

`TransferGate#shares_a_fleet?` becomes `known_to_each_other?` and answers over the same four-case pattern match it already uses:

| recipient | sender | known when |
|---|---|---|
| user | user | a fleet in common **or an accepted friendship** |
| user | fleet | the user is a member |
| fleet | user | the user is a member |
| fleet | fleet | the same fleet **or an accepted alliance** |

That is the whole backend change to transfers, and it is deliberately the only one:

- It does not touch `check_rule`. A standing deny still refuses, because the gate evaluates the rule *after* the policy and a deny is not overridable (`OVERRIDABLE = %i[policy cap]`). Befriending somebody who has denied you changes nothing, which is correct — a relationship widens a stance, it does not delete an exception to one.
- It does not touch `nobody`. A closed policy stays closed to friends and allies alike.
- It does not touch `check_recipient_can_receive` or `check_sender_not_sanctioned`. Neither is the recipient's to waive, and neither becomes waivable by being liked.

### D10 — Allied fleets are targets only when sending on a fleet's behalf

In `useTransferTargets`, friends join the party picker's grouping — the extension point its own comment describes — and allied fleets join `fleetTargets`. But `fleetTargets` is currently built from `useMyFleets()`, and your fleet's allies are not your fleets. You have no standing in them.

So an ally is offered as a target exactly when `fleetSlug` is set, i.e. when the transfer is being sent from a fleet inventory on that fleet's behalf. A user shipping from their own hangar sees their friends and their own fleets, and not the fleets their fleet happens to be allied with — because the alliance is between the two organisations and not between an organisation and each individual member of the other.

Targets stay filtered on feature availability only, never on whether the gate would admit the sender. That rule is already in place and is the reason a policy or a denial cannot be read off an option going missing.

### D11 — Two flags, because there are two surfaces with two self-service scopes

`friends` and `fleet_allies`, registered in `config/feature_flags.yml`. Not one `social_graph` flag: `FeatureSetting` carries `self_service_user` and `self_service_fleet` independently, a user switching their own friends on has nothing to do with a fleet's admins switching alliances on for the org, and the two roll out on their own schedules. This is the `hangar_inventories` / `fleet_logistics` split, for the same reason.

Composition with the transfer feature is by conjunction, per #4878 D15: a friend only widens `known` where `inventory_transfers` is also on for the recipient. A flag never becomes a way around another flag.

Adding both names to the schema's `FeatureFlagName` enum is a schema regeneration, and on a stack it takes every descendant branch red until each is rebased. That is expected, not a surprise to debug.

### D12 — Alliances are an admin act, with their own privileges

An alliance commits the fleet's ships, stats and roster to another organisation. That is not an officer's call by default.

```ruby
FleetAlliance::AVAILABLE_PRIVILEGES = %w[
  fleet:allies:read fleet:allies:create fleet:allies:delete fleet:allies:manage
]

DEFAULT_PRIVILEGES = {
  admin:   [],                        # covered by fleet:manage
  officer: ["fleet:allies:read"],
  member:  []
}
```

Members see nothing about alliances by default, officers can see who the fleet is allied with, and only `fleet:manage` (or an explicitly granted `fleet:allies:manage`) sends, answers or ends one. New `CAPABILITY_PRIVILEGES` entries — `read_allies`, `create_allies`, `destroy_allies`, `manage_allies` — so the client gates on evaluated booleans and no privilege string reaches the frontend.

### D13 — Soft-deleted fleets, and the cap

`Fleet` is `Discard::Model`, so a discarded fleet's row survives and its alliances with it. Every read scopes through `.kept` on the other side; an alliance with a discarded fleet shows nowhere and admits nothing, and comes back if the fleet is restored — which is what soft delete is for.

An outstanding-incoming cap on both request kinds, following `InventoryTransfer::OUTSTANDING_LIMIT`. One account cannot fill a stranger's inbox in a burst, and a Rack::Attack throttle on the two create endpoints alongside the existing per-endpoint rules covers the rest.

### D14 — One deploy, nothing to backfill

Two new tables, six new boolean columns defaulting to `false`. The previous release writes no relationships and reads no new columns, so there is no window where the old code produces a row the new code cannot read, and none where the new columns being absent matters. The migration runs in the pre-deploy hook before the new containers boot, and drops nothing — the failure mode where the old release 500s on a column it never referenced does not apply.

## What changes

### Phase 1 — The two relationships and the handshake
1. Migration: `friendships` and `fleet_alliances` per D1 — cascading foreign keys, the unordered unique index and the not-self check constraint on each, plus per-column indexes for the inbox reads.
2. `PartyRelationship` concern: the AASM block (`pending → accepted | declined | ignored`), `between(a, b)` over the unordered pair, `#other_party_for`, the cap, and `has_paper_trail` with a `VersionedItem::ROOTS` entry.
3. `Friendship` and `FleetAlliance`, each naming its two associations and its `ransackable_*`.
4. `Users::RelationshipRequester` / `Fleets::AllianceRequester` — one service per side owning D4: accept a crossing request, absorb into an ignored row, reopen a declined one, otherwise create.
5. Answer paths: accept, decline, ignore, cancel (by the requester) and end (by either side, destroying the row).

### Phase 2 — What a friend can see
1. Migration: `friends_hangar`, `friends_hangar_stats`, `friends_wishlist` on `users`, all `default: false, null: false`.
2. `User#friends` / `#friend_of?(other)` over the accepted rows, and the `has_paper_trail` `only:` list gains the three new columns beside the `public_*` ones it already records.
3. `Public::UserPolicy` — the three widening clauses per D6 and D7.
4. The two inline checks in `Api::V1::Public::VehiclesController` move to the policy; the bulk filter in `HangarsController#index` becomes a friendship-aware scope.

### Phase 3 — What an ally can see
1. Migration: `allies_fleet`, `allies_fleet_stats`, `allies_fleet_members` on `fleets`.
2. `Fleet#allies` / `#allied_with?(other)`, scoped `.kept` per D13.
3. `Public::FleetPolicy#show?` and `#show_stats?` widened independently per D7, plus a new `show_members?`.
4. `Api::V1::Public::FleetMembersController` and `_allied_member.jbuilder` per D8 — the reduced payload, `hide_owner` omission, and a count that still includes the omitted.
5. The ally's route into the vehicle and stats endpoints, verified to still honour every member's `ships_filter`.

### Phase 4 — Transfers
1. `TransferGate#shares_a_fleet?` → `known_to_each_other?` per D9, with the friendship and alliance arms.
2. Nothing else in the gate, the authorizer, the resolver or the executor changes. That is the deliverable of this phase as much as the method is.

### Phase 5 — API
1. `resources :friendships, path: "friends", param: :username` with `index`, `show`, `create`, `destroy` and `put :accept` / `put :decline` / `put :ignore` on the member — the shape `fleet_members` already uses for a two-step flow (`config/routes/api/fleets_routes.rb:17`). One resource, filtered by `q[state]`, rather than a second requests resource.
2. `resources :fleet_alliances, path: "allies", param: :slug` under `fleets/:slug/`, with the same member actions.
3. Settings: the three user flags on `me`, the three fleet flags on the fleet update endpoint, each behind its existing strong-parameter list.
4. Policies: `FriendshipPolicy` and `FleetAlliancePolicy`, the latter delegating to the D12 privileges.
5. Schemas in `app/api_components/v1/`: `Friendship`, `FleetAlliance`, the shared relationship-state enum, the two create inputs, the two list schemas, `AlliedFleetMember`, and the two new `FeatureFlagName` values. Then `./bin/generate-schema` and an `oasdiff` check — expecting no breaking entries, which is what D6 buys.
6. Orval regeneration for both generated clients.

### Phase 6 — Notifications
1. Four `notification_type` values with their `TYPES` entries, retention and `preference_defaults`, per D5.
2. Recipient resolution for the fleet side reuses the ally-manager privilege walk rather than copying the membership walk.
3. Accept and decline as call-to-actions on both `_received` types.
4. Strings in all seven locales.

### Phase 7 — Frontend
1. A friends page: the list, incoming and outgoing tabs, and the three answers. Ignored requests behind a filter, never in the default view.
2. A fleet allies page under `fleets/[slug]/`, gated on the `read_allies` capability, with the manage actions gated on `manage_allies`.
3. `settings/privacy.vue` gains the three friend toggles, each disabled with an explanation while the matching `public_*` flag is on — the one place D6's "public wins" rule has to be visible rather than merely true.
4. Fleet settings gain the three ally toggles.
5. `useTransferTargets` per D10: friends in the party grouping, allied fleets in `fleetTargets` when acting for a fleet.
6. Route `meta.title` in both the `nav.*` and `title.*` namespaces, and every string in all seven locale files.

### Phase 8 — Tests
Written per phase. The state machine including all three answers; a table test over D4's four request-meets-existing-row cases; **an ignore test asserting the requester's serialised payload is byte-identical to a pending one**, since D3 is the decision the feature turns on. Policy tests over public × friend-flag × friendship for each of the three user surfaces and each of the three fleet ones, including the "public on, friend flag off" cell. An integration test that the ally member payload carries none of the fields `_base.jbuilder` does, asserted by key set rather than by sampling. A gate test that a friend satisfies `known`, that a friend under a deny rule still does not, and that `nobody` is unmoved. A cap test and a Rack::Attack test on both create endpoints. Vitest for the toggle-disabling rule and for the extended target list. One Playwright pass over request → accept → the newly visible hangar.

## Intent Verification

- [ ] **Both handshakes work end to end** — request, then accept, decline or ignore, from either side, for users and for fleets.
- [ ] **Ignore is undetectable** — the requester's view of an ignored request is identical to a pending one, field for field, and a re-request returns success while changing nothing.
- [ ] **Ignore is durable** — a further request from an ignored sender never reaches the recipient's inbox, and never becomes an acceptance by way of D4.
- [ ] **A crossing request is an acceptance** — B asking A while A's request is pending produces one accepted relationship, not an error and not two rows.
- [ ] **One row per pair** — the database refuses a second relationship between the same two parties in either direction.
- [ ] **Nobody is pinged about a refusal** — declining or ignoring writes no notification of any kind.
- [ ] **A relationship opens nothing on its own** — with every new flag off, a friend and an ally see exactly what an anonymous visitor sees.
- [ ] **Public still wins** — turning a friend flag off while the public flag is on changes nothing for anybody.
- [ ] **No existing value changed meaning** — `public_hangar` and its four siblings serialise as the booleans they always did, and `oasdiff` reports nothing breaking.
- [ ] **The three non-policy call sites were found** — a non-public hangar readable by a friend is readable through the hangar page, the vehicle endpoints *and* the multi-hangar compare, with no path left behind.
- [ ] **An ally sees a reduced roster** — the allied member payload contains no contact handle, no coordinate, no current system and no activity timestamp, asserted over the whole key set.
- [ ] **A hidden member stays hidden** — `hide_owner` omits them from an ally's list while still counting them in the fleet's totals.
- [ ] **Every member's ship choice survives** — a member who set `ships_filter` to `hide` has no vehicle visible to an ally, and one on `hangar_group` has only the group's.
- [ ] **`known` gained exactly two meanings** — a friendship for user↔user and an alliance for fleet↔fleet, with the other two arms of the match untouched.
- [ ] **A denial still refuses a friend** — an `InventoryTransferRule` deny outranks a friendship, and a `nobody` policy is unmoved by one.
- [ ] **Allies are targets only from a fleet** — a user sending from their own hangar is never offered their fleet's allies.
- [ ] **The pickers leak nothing** — a target list is filtered on feature availability only; no policy, denial or sanction is readable from an option being absent.
- [ ] **Alliances are an admin act** — an officer without `fleet:allies:manage` can read the ally list and cannot send, answer or end an alliance, and no privilege string reaches the client.
- [ ] **A discarded fleet is not an ally** — its alliances admit nothing while it is discarded and are intact when it is restored.
- [ ] **An inbox cannot be flooded** — the cap and the throttle both hold on both request kinds.
- [ ] **Both flags gate independently** — `friends` off leaves fleet alliances working, and `fleet_allies` off leaves friendships working.

## Key files

| File | Role |
|------|------|
| `app/services/inventories/transfer_gate.rb` | `shares_a_fleet?` (`:113`) — the one method D9 changes; `OVERRIDABLE` (`:22`) is why a deny still wins |
| `app/models/concerns/inventory_transfer_party.rb` | `POLICIES` (`:20`) — the `known` stance this feature gives two more meanings |
| `app/frontend/frontend/composables/useTransferTargets.ts` | The party picker, and the comment naming a friends list as its extension point |
| `app/models/fleet_membership.rb` | The two-step handshake this copies (`aasm:159`); `CAPABILITY_PRIVILEGES` (`:130`); `ships_filter`, which D8 inherits rather than reimplements |
| `app/policies/public/user_policy.rb` | The three clauses D7 widens |
| `app/policies/public/fleet_policy.rb` | `show?` and `show_stats?` (`:4`, `:8`) — widened independently, per the trap in D7 |
| `app/policies/fleet_base_policy.rb` | `fleet_membership` — how a policy already reaches the current user's standing in a fleet |
| `app/controllers/api/v1/public/vehicles_controller.rb` | The two inline `public_hangar?` checks (`:13`, `:25`) that are not policies |
| `app/controllers/api/v1/public/hangars_controller.rb` | The bulk `public_hangar: true` filter (`:42`) — the third call site, and the one that is a join |
| `app/views/api/v1/fleet_members/_base.jbuilder` | What an ally must **not** receive; the field list D8 is a reaction to |
| `app/views/api/v1/fleet_vehicles/_vehicle.jbuilder` | `hide_owner` (`:9`) — the precedent D8 follows for the roster |
| `app/models/user.rb` | The `public_*` booleans (`:43`) and the `has_paper_trail` `only:` list (`:98`) the new flags join |
| `app/models/fleet.rb` | `public_fleet` / `public_fleet_stats` (`:19`); `AVAILABLE_PRIVILEGES` (`:42`) beside which D12's are registered |
| `app/models/notification.rb` | `notification_type` (`:39`) and `TYPES` (`:66`) — and the absent decline types that justify D5 |
| `config/feature_flags.yml` | Where `friends` and `fleet_allies` are declared |
| `config/routes/api/fleets_routes.rb` | `fleet_members` with `put :accept` / `put :decline` (`:17`) — the route shape Phase 5 follows |
| `app/frontend/frontend/pages/settings/privacy.vue` | Where the three user toggles land |
| `config/initializers/rack_attack.rb` | The per-endpoint throttle precedent D13 follows |

## Not in scope (deferred)

- **A platform-wide block.** D3's absorbing ignore is a per-relationship block and is what this feature needs. A block that also hides your profile, suppresses mentions and pre-empts every other interaction is a separate feature with its own moderation surface, and bolting it onto a friend request is how it gets built wrong.
- **Friends of fleets, or allies of users.** Membership already expresses user↔fleet, and adding a fourth combination would force the polymorphic shape D1 rejected for the sake of a relationship nobody asked for.
- **Consolidating the visibility booleans into an enum.** D6 explains why not from inside a stack. Worth doing in a deliberate breaking release, together rather than one at a time.
- **Friend groups or tiers.** "Close friends see the wishlist too" is a real want and is a second dimension on every one of the six flags. Not until the flat version has users.
- **Sharing a fleet's inventories with an ally.** Reading another org's stock levels is a much larger disclosure than reading its ships, and transfers already work between allies without it.
- **Mutual-friend suggestions or any discovery surface.** Requires a search over the graph and has its own privacy questions.

## Discovery Log

- **2026-09-13** Initial research and plan creation.

- **2026-09-13** Built, all eight phases. Nine things the plan did not say, each
  found by building it:

  **The two tables use the same column names.** D1 sketched
  `requester_fleet_id`/`addressee_fleet_id` for alliances. They are
  `requester_id`/`addressee_id` in both tables instead: the table already says
  which type each end is, and same-named columns are what let `PartyRelationship`
  own the handshake outright rather than through a mapping.

  **One requester service, not two.** With the columns identical, D4's four cases
  are the same code for both relationships, so `Relationships::Requester` takes
  the relation class as an argument.

  **`Friendship` is not versioned.** Phase 1 said `has_paper_trail` for both. A
  version of a friendship holds both user ids -- a record of who knew whom,
  surviving one of them deleting their account, which is the thing
  `ErasableVersionsConcern` exists on `User` to prevent. `FleetAlliance` keeps it:
  an alliance is a governance act. Neither gets a `VersionedItem::ROOTS` entry,
  because an alliance has two fleets with equal claim to being its root --
  `InventoryTransfer` has no entry either, for a similar reason.

  **Ignoring had a second tell, and then a third.** `state_for` hides an ignored
  request from its sender, and two things gave it away anyway. A list filtered on
  the column would omit it from the sender's pending list, so listing goes through
  `in_state_for(state, party)` rather than ransack. And `cancellable_by?`,
  asked of the real state, refused to withdraw it -- so it is asked of the state
  the requester can see, and `Answerer#cancel` answers success and leaves an
  ignored row standing. Destroying it would have made withdraw-and-ask-again a
  way back into an inbox that turned you away.

  **A hidden member keeps their row.** D8 said `hide_owner` omits a member from an
  ally's list; the payload carries `hidden: true` and drops the name instead. It
  is what `_vehicle.jbuilder` already does, and it keeps the roster honest about
  how large the fleet is.

  **Ally visibility settings ride the existing fleet-update privilege.** D12's new
  privileges govern *alliances*; the three visibility columns sit with
  `public_fleet` under `fleet:manage`/`fleet:update`, where every other visibility
  switch already is.

  **Notification call-to-actions, for friendships only.** A notification's record
  reference is computed from the record, and for a friendship the reader is
  unambiguously one of the two parties -- so it can be addressed by the other
  one. An alliance cannot: the reference would have to guess which of the two
  fleets the reader is acting for. Its notification links to the allies page,
  which is where it is answered.

  **`api-schema-breaking` needed 85 ignore lines, and five have no precedent.**
  Four `fleet:allies:*` privileges and four notification types are enum values on
  published responses, which `oasdiff` fails on; the file already carries 907 such
  lines. 80 of the new ones match an existing line except for the value. The five
  for `record/type` are the first notification *record* type added since the file
  was written, so their wording has no counterpart to check against -- written
  with oasdiff 1.31.0 against CI's pinned 1.18.1. The rule and its message are the
  same in both; the property path comes from the schema. Worth a glance at the CI
  job.

  **Two things adjacent to this are left alone.** `de`/`es`/`fr`/`it`/`zh-*`
  `notifications.yml` lack the `inventory_transfer_*` titles #4881 added to `en`
  -- a parity gap on the branch below this one, not this branch's to close. And
  there is no Playwright pass: the plan asked for one over request → accept → the
  newly visible hangar, and it is the one item not delivered. Confirmed `TransferGate#shares_a_fleet?` is the single definition of `known`, and that `useTransferTargets` already documents a friends list as its intended extension. Measured the ally-roster problem against `fleet_members/_base.jbuilder`, which renders coordinates, current system and four contact handles per member — the reason D8 builds a second partial rather than reusing it. Found three `public_hangar` checks outside the policies, one of them a bulk filter. Confirmed `ApplicationPolicy` authorizes an optional `user`, so the public policies can already ask who is reading.

- **2026-09-13** Review (PR #4889) found four things, three of them real
  boundaries:

  **Withdrawing an ignored request was the one place the ignore showed.** Every
  surface hid it and the *absence* of a surface did not: a real withdrawal
  destroys the row, an ignored one had to survive to keep absorbing, so it came
  back in the sender's next list. `withdrawn_at` on both tables fixes it — hidden
  from `in_state_for`, 404 on a direct read, still absorbing, cleared by a fresh
  request. The test asserts withdraw → read → list → re-request answers
  identically for an ignored row and a plain one.

  **`POST` could accept an alliance with only the create privilege.** D4 makes a
  crossing request an acceptance, which means the create endpoint can complete a
  relationship rather than only propose one — so it authorizes `accept?` on that
  path as well.

  **D7 was right and the code did not follow it.** The plan says folding the ally
  clauses together would let `allies_fleet_stats` open the fleet page; it was
  added to `show?` anyway, reasoning from `public_fleet_stats?` already being
  there. What that missed is that `show?` guards
  `Public::FleetVehiclesController` too, so "share our numbers" also handed over
  the ship list with loadouts, modules and owner avatars. Now one switch, one
  surface. The pre-existing `public_fleet_stats?` clause is left alone — same
  shape, but changing it alters published behaviour and belongs in its own
  change.

  **Existing-row transitions were not serialized**, so two simultaneous
  re-requests could both reopen a declined relationship and both notify. They run
  under a row lock now, and notifications moved outside the transaction: a
  broadcast must not be able to roll back a relationship that was agreed to.

- **2026-09-14** Using it found five things, and one of them was a crash.

  **The friends list moved under settings.** It was a top-level sidebar entry of
  its own; it is a settings tab now, between Hangar and Privacy — which is where
  the switches it governs already live, `friends_hangar` and its two siblings.
  The four tab routes moved with it (`settings-friends*`), `/friends/:tab*`
  redirects to the new one because notifications written before the move carry
  `/friends` as their link and those rows outlive it, and the Rails helper moved
  rather than being renamed, so `Relationships::Notifier` is untouched.

  **A request can be sent from a public hangar.** Asking somebody to be a friend
  meant knowing their username well enough to type it, which is the one thing
  somebody reading their hangar already has. The button reads the existing
  `GET /friendships/:username` — a 404 is "no relationship", which is precisely
  when it has something to do — so nothing was added to the public user payload,
  whose partial is cached per user and would have had to render per reader. Four
  states, and two of them are not buttons: a request sent says so, a friendship
  says so, an incoming request is answered rather than crossed with another, and
  a request this reader *ignored* offers nothing at all, because a further
  request from them is absorbed and the button would go nowhere.

  **`l(createdAt, "short")` crashed the list.** The helper takes a full key path,
  so the format string handed to `date-fns` was
  `[missing "en.short" translation]` — a `RangeError` on the first unescaped
  letter, which unmounted the allies table mid-render. Every other caller in the
  app passes `datetime.formats.short`.

  **Four notification types had no label in any locale.** `friend_request_*` and
  `fleet_ally_request_*` render their own key in the notification list and had no
  row in the notification settings at all — the groups there are a hand-kept list
  and nothing had been added to it. They are a fifth group now, "Friends &
  allies", and the labels are written in all seven locales. `FormInput` falls
  back to `placeholders.<name>` when it is given none, so the add-a-friend field
  showed `[missing "en.placeholders.handle" translation]` inside the box; the
  modal takes a placeholder now, per kind.

  Confirmed while reading: `alliesFleetMembers` is deliberately the one ally
  switch with no `narrowerAudienceDisabled` guard. The roster has no public
  counterpart to be overridden by — `Public::FleetPolicy#show_members?` says so
  — so there is nothing for it to sit under.

  **And a sixth: disabling the narrower switch was only half of saying so.** Off
  and greyed reads as "allies cannot see the ships", which is the opposite of
  what a public fleet means — the five switches under a public one were all
  showing the negative of what was true. `FormToggle` takes `implied` now: it
  reads as on while the wider switch covers it and keeps its own value
  underneath, so turning public off again restores the choice that was made
  rather than the one it was shown as. That meant replacing the element's
  `v-model` — which is where the `update:modelValue` emit rode, the only path a
  parent's own `v-model` has. The hangar sync modal's test caught it; the emit is
  explicit now, and has its own case.

  **Add-an-ally moved into the app header**, where a fleet page's actions already
  live — its members, events and logistics pages all teleport there. Add-a-friend
  stays over its list: a settings tab has no header of its own, and nothing under
  `/settings` teleports into that one. So `RelationshipView` takes `headerAction`
  rather than reading its `kind`, and the toolbar slot goes away with the button
  instead of rendering empty — `FilteredList` reserves the right-hand column for
  a slot that merely exists, which on a phone decides whether the paginator wraps.

## Progress
- [x] Phase 1 — The two relationships and the handshake
- [x] Phase 2 — What a friend can see
- [x] Phase 3 — What an ally can see
- [x] Phase 4 — Transfers
- [x] Phase 5 — API
- [x] Phase 6 — Notifications
- [x] Phase 7 — Frontend
- [x] Phase 8 — Tests *(except the Playwright pass — see the Discovery Log)*
