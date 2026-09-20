# Online status from the cable connection

## Goal

A live green dot next to a user's name on the fleet roster, the friends list and the three admin
surfaces, driven by the websocket the browser already holds, updating without a reload.

## Context

`users.last_active_at` is a 15-minute-granular timestamp, not a state: it never changes while a
page is open, so nothing on a roster ever updates. The connection that answers the question exists
already — every visitor with the app open holds a cable socket, and `ApplicationCable::Connection`
already knows who a signed-in one belongs to.

Resolves #4990

## Decisions

### D1 — Presence lives in one sorted set, not one key per connection

The issue sketches `presence:conn:<user_id>:<token>` with a TTL. A single sorted set in `cable_db`
— member `"<user_id>:<token>"`, score the unix time the connection stops counting — answers the
same questions and two more the per-key form cannot:

- **A page needs one read.** `ZRANGEBYSCORE presence:connections (now +inf` returns every live
  connection in the system in one call. The per-key form needs a `SCAN` per user, or a key
  enumeration whose cost grows with the keyspace. Measured concurrency is 57 users in a 15-minute
  window, so the whole live set is a few hundred members — small enough to read whole and
  intersect in Ruby.
- **The reaper needs to know who *just* left.** An expiring key fires no event and leaves nothing
  behind to diff against. A score-ordered set gives both halves: who is live now
  (`ZRANGEBYSCORE`) and what has aged out (`ZREMRANGEBYSCORE -inf now`).

Expiry is still automatic in the sense that matters: every read filters on score, so a member whose
score has passed is invisible whether or not the reaper has run yet. The reaper only trims and
emits.

### D2 — The grace period is encoded in the score, not in a separate timer

A reload is a disconnect followed by a connect a second later, and emitting both would flap a dot
on every co-member's roster. Rather than tracking "offline since" per user, `disconnect` rewrites
its own member's score to `now + 60s` instead of removing it. The connection then counts as live
for one more minute, so:

- a reload never leaves a gap — the new connection is live before the old member's grace runs out
- closing one of four tabs changes nothing, because the other three are still live on their own
- closing the last tab reads as offline exactly one minute later
- `kill -9` writes nothing at all, so the member ages out at its full 90-second TTL

One mechanism covers the debounce, the multi-tab case and the ungraceful loss.

### D3 — Online is announced from `connect`, offline from a job

Green has to arrive "within seconds", so `Connection#connect` enqueues the fan-out itself — via
Sidekiq, not inline, because the fan-out reads fleets and friendships and must not block the cable
thread. Grey is inherently late, so it comes from a reconcile pass: `Presence::OfflineCheckJob`
scheduled at `+grace` by `Connection#disconnect` for the graceful case, and
`Presence::SweepJob` once a minute as the backstop for every case where no callback ran.

Both paths call the same reconcile: diff the live set against `presence:announced`, emit what
changed, update the set. That set is what makes a reload silent — the user never leaves it, so the
reconnect finds nothing to announce.

### D4 — The heartbeat subscription is not behind the feature flag

`UserPresenceChannel` is subscribed by every authenticated client, flag or no flag, and its
`periodically` refreshes the connection's score. Only the fan-out, the REST field and the UI are
gated.

Gating the subscription instead would make the store wrong rather than empty: Flipper gates are
per-actor, so a percentage rollout would leave flagged-in users seeing flagged-out ones drop
offline 90 seconds after connecting. The cost of not gating it is one `ZADD` per connected client
per 30 seconds.

### D5 — The opt-out is applied on read, never on write

`show_online_status` (new, default **on**) is checked where presence is rendered and where it is
broadcast to co-members and friends — not where it is recorded. Admins read the store directly and
see the truth, which is the behaviour the decision asked for and is impossible if the switch
suppresses the write.

Flipping the switch while connected broadcasts the new visible state, so it takes effect without a
reconnect.

### D6 — `online` is optional in the schemas, absent when the flag is off

All three payload schemas carry `additionalProperties: false`, so the field has to be declared.
Declaring it **not required** lets the jbuilder omit it entirely when `online_status` is off for
the reader, rather than shipping `false` — which would be a claim, not an absence. The frontend
renders a dot only for a defined value.

### D7 — A dedicated channel, and a presence map the surfaces read from

A transition is two fields. Riding on `FleetMembersChannel` would render a full `FleetMember`
jbuilder per recipient — 702 renders in the worst case. `UserPresenceChannel` /
`AdminPresenceChannel` carry `{userId, online, lastActiveAt}`.

The client keeps one module-level map keyed by user id, written by the subscription and read by
every surface with the REST payload as the fallback. That way a roster, a friends list and a member
modal open at once all agree, and a page that holds no subscription of its own still updates.

The map wins over the REST value when it holds an entry, and is cleared on a cable reconnect —
nothing is replayed, so anything it held across the gap is unverifiable.

## What changed

### Phase 1 — The presence store

1. `app/lib/user_presence.rb` — the sorted set, the announced set, the reconcile, and the read used
   by the jbuilders. Its own `ActiveSupport::Cache::RedisCacheStore` on `cable_db`, namespaced by
   `Process.pid` under `Rails.env.test?` like `ApiUsageTracker`, because parallel test workers
   share one Redis.
2. `test/lib/user_presence_test.rb`.

### Phase 2 — Connection lifecycle and the channels

3. `ApplicationCable::Connection` — a `presence_token` per connection, the `connect` write plus the
   online announcement, and a `disconnect` hook that writes the grace score and schedules the check.
4. `app/channels/user_presence_channel.rb` — `periodically` heartbeat, `stream_for current_user`.
5. `app/channels/admin_presence_channel.rb` — `stream_for current_admin_user`.
6. `app/api_components/cable/v1/schemas/user_presence_message.rb` and the admin twin.
7. `test/asyncapi/user_presence_channel_test.rb`, `test/asyncapi/admin_presence_channel_test.rb`,
   `test/channels/`.

### Phase 3 — Fan-out and the reaper

8. `app/jobs/presence/broadcast_transition_job.rb` — co-members of every accepted membership,
   accepted friends in both directions of the pair, and every admin user.
9. `app/jobs/presence/offline_check_job.rb`, `app/jobs/presence/sweep_job.rb`, the schedule entry.
10. `config/feature_flags.yml` — `online_status`.

### Phase 4 — The opt-out and the REST payloads

11. Migration: `users.show_online_status`, boolean, default true, not null.
12. `User` — paper-trail coverage, and the broadcast when the switch moves.
13. Strong params, `UserUpdateInput`, the `User` response schema, the privacy page.
14. `PresenceReadable` concern giving the controllers a per-request memoised online set.
15. `online` on `FleetMember`, on the friendship's nested user (with `lastActiveAt`, which it does
    not carry today) and on the admin `User` and `AdminFleetMember` — emitted **outside** the
    `json.cache!` blocks, which key on records presence does not touch.
16. `TrackingStatsConcern#active_users_count` reads the presence set.

### Phase 5 — The frontend

17. `shared/composables/usePresence.ts` — the map and its readers.
18. `frontend/composables/usePresenceUpdates.ts` + `admin/composables/useAdminPresenceUpdates.ts`,
    mounted from `useUpdates` and the admin equivalent.
19. `shared/components/PresenceDot/` and an `online` prop on `Avatar`.
20. The six surfaces, the `RelationshipRow` shape (optional, `kind="user"` only), and translations
    in all seven locales.

## Intent Verification

- [ ] **Green within seconds** — a member opening the site turns their dot green on every
      co-member's roster and every friend's list, with no reload
- [ ] **Grey within the grace period** — closing the tab greys the dot, and a reload does not flap it
- [ ] **No stuck presence** — `kill -9` on a worker leaves nobody online past the TTL
- [ ] **One presence per user** — four tabs and a phone are one dot; closing one changes nothing
- [ ] **Correct on first paint** — a roster loaded fresh shows the right dots before any transition
- [ ] **Admins see all three surfaces** — users list, user detail, admin fleet roster
- [ ] **Opt-out is honoured** — an opted-out user reads offline to co-members *and* friends, and
      truthfully to admins
- [ ] **Only accepted friendships leak** — pending, declined and ignored show nothing, in both
      directions of the pair
- [ ] **Alliances render no dot** — the shared `RelationshipView` stays fleet-safe

## Key files

| File | Role |
|------|------|
| `app/lib/user_presence.rb` | the store, the reconcile and the read |
| `app/channels/application_cable/connection.rb` | where a connection starts and stops counting |
| `app/channels/user_presence_channel.rb` | the heartbeat that refreshes the score |
| `app/jobs/presence/broadcast_transition_job.rb` | the fan-out |
| `app/jobs/presence/sweep_job.rb` | the backstop for connections that died silently |
| `app/frontend/shared/composables/usePresence.ts` | the map every surface reads |

## Not in scope (deferred)

- **Presence on public hangar and profile pages** — this is for accepted relationships
- **Presence on the fleet alliances list** — the other party there is a fleet
- **OAuth/API clients** — they hold no socket
- **An "away" state** — the socket says connected, not attentive
- **Moving `last_active_at` onto the heartbeat** — it would turn a quarter-hourly write into a
  30-second one per connected user

## Discovery Log

- **2026-09-20** Research and plan. The five open decisions in the issue were settled as
  recommended and written back into the issue body.

## Progress
- [x] Phase 1 — The presence store
- [x] Phase 2 — Connection lifecycle and the channels
- [x] Phase 3 — Fan-out and the reaper
- [x] Phase 4 — The opt-out and the REST payloads
- [x] Phase 5 — The frontend
