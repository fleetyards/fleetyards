# Fleet RSI SID verification and FID claims

Working plan for #5273. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fleet can prove it controls an RSI org by putting a token on the org page. A verified fleet can then claim the FID equal to its SID from whoever holds it, after a 14-day grace period.

Two stacked PRs:
- PR 1 (this branch): normalisation and verification.
- PR 2: FID claims.

## Open questions
- None for PR 1.

## What changed

### Phase 1 — Normalise `rsi_sid`
1. `Fleet#rsi_sid=`: trim; extract the SID from `robertsspaceindustries.com/(en/)orgs/<SID>` with or without a scheme; strip `[]`, a trailing `/`, a leading `@`; upcase.
2. Validate format `/\A[A-Z0-9]{1,10}\z/`, allow blank.
3. Data migration in `db/data/`: normalise every kept and discarded fleet; set values that still fail the format to nil. Test it in `test/migrations/`.
4. `verify_fleet_memberships` keeps `UPPER(rsi_sid)` working. Now that the column is canonical, compare it directly.

### Phase 2 — Verification model and job
1. Migration: `rsi_verification_token`, `rsi_verification_checked_at`, `rsi_verified_at`, `rsi_verified_sid`, plus a partial unique index on `rsi_verified_sid` where `discarded_at IS NULL`.
2. `Fleet`:
   - `rsi_verified?`
   - `reset_rsi_verification` when `rsi_sid` changes
   - `generate_rsi_verification_token!`
   - clear the verification on discard, so the SID is freed
3. `Rsi::OrgPageVerifier` (app/lib/rsi): Typhoeus GET `/en/orgs/<SID>`. Returns `:verified`, `:token_missing`, `:symbol_mismatch`, `:not_found` or `:error`. Blocked requests are recorded via `RsiRequestLog`, like `BaseLoader`.
4. `FleetRsiVerificationJob` (Sidekiq):
   - runs the verifier
   - on success, takes the SID away from any other kept fleet, then sets the fields; all in one transaction
   - notifies the previous fleet's managers
   - broadcasts the result
5. No cable channel: the status is stored on the fleet and the panel polls while it is `pending` (see Discovery Log).

### Phase 3 — API
1. `POST /fleets/:slug/rsi-verification` generates or rotates the token.
2. `POST /fleets/:slug/rsi-verification/check` queues the job; returns 429 inside the cooldown.
3. `GET /fleets/:slug/rsi-verification` returns the status, token and last check.
4. The policy gates all three on `fleet:manage`.
5. Schemas and `generate-schema`.
6. `rsiVerified` on the fleet schemas.
7. Public jbuilder: `rsi_sid` only when verified.
8. Admin:
   - verified column and filter
   - `DELETE /admin/.../fleets/:id/rsi-verification` to revoke

### Phase 4 — Frontend
1. Fleet settings (`settings/fleet.vue`) gets a verification panel:
   - token with copy
   - link to the RSI org page
   - check button
   - live result via the channel
2. The public page (`[slug]/index.vue`) shows the RSI link only when verified, plus a verified or unverified mark.
3. Settings banner for an SID-shaped FID on an unverified fleet.
4. Admin fleets list column and a revoke action on the detail page.
5. Hand-translate the labels into all 7 locales. Notification types need entries in `notification_examples.rb`.

## Intent Verification

- [ ] **A fleet proves an org**: with the token on a fixture org page, the check verifies the fleet. A missing token, a symbol mismatch and a 404 each leave it unverified with a distinct error.
- [ ] **Latest proof wins**: fleet B verifying an SID already held by fleet A moves it, and A's managers get a notification.
- [ ] **Changing `rsi_sid` unverifies**, and so does an admin revoke.
- [ ] **Public output hides an unverified SID**: the public JSON has no `rsiSid` for an unverified fleet.
- [ ] **Normalisation**: a URL, a lowercase value, surrounding whitespace, `[GIT]` and `VERSEGUARD/` all store the bare SID; a handle or `#123` is rejected.
- [ ] **Membership verification** matches a fleet that previously stored an org URL.

## Key files

| File | Role |
|------|------|
| `app/models/fleet.rb` | normalisation, validation, verification helpers |
| `app/controllers/omniauth_callbacks_controller.rb:204` | `verify_fleet_memberships` SID match |
| `app/policies/fleet_policy.rb` | `fleet:manage` gate, `params_filter` |
| `app/lib/rsi/base_loader.rb` | Typhoeus and `RsiRequestLog` pattern |
| `app/lib/hangar_sync.rb`, `app/channels/hangar_sync_channel.rb` | job-to-cable result pattern |
| `app/models/notification.rb`, `app/models/fleet_membership.rb:362` | fleet manager notifications |
| `app/views/api/v1/public/fleets/_base.jbuilder` | public SID exposure |
| `app/frontend/frontend/pages/fleets/[slug]/settings/fleet.vue` | settings form |
| `app/frontend/frontend/pages/fleets/[slug]/index.vue:122` | public RSI link |
| `app/frontend/admin/pages/fleets/index.vue` | admin column |
| `test/fixtures/rsi/` | org page fixture |

## Not in scope (deferred)
- **FID claims, grace period, rename to `X-N`** — PR 2, stacked on this branch, same issue.
- **Public fleet directory** — its own issue after #5273; `listed` opt-in, verified, at least 2 accepted members.

## Discovery Log

- **2026-09-28** Initial research and plan. `rsi_sid` has no validation or index. The public schema reuses `v1/schemas/fleets/fleet.rb`. Controllers have no per-record rate limiting.
- **2026-09-28** Cooldown is `rsi_verification_checked_at` on the fleet. A check inside it answers with the current state and does not reach RSI.
- **2026-09-28** Dropped the cable channel. The check takes about a second, so `rsi_verification_status` on the fleet plus a 2s poll while `pending` is enough, and it avoids a channel, its asyncapi entry and a generated client.
- **2026-09-28** `api/v1/public/fleets/_base.jbuilder` had not been rendered since the Vue 3 migration; the public payload renders the members' partial. Deleted it. The public partial gets its own cache key and a `visitor` flag, because Jbuilder is `ignore_nil`, so assigning nil after the cached block cannot remove the key.
- **2026-09-28** `[slug].vue` raced the public and members' fleet queries, and a member's settings form could seed itself from the visitor payload. Once the payload hid an unverified SID, the field came up empty. A signed-in reader now falls back to the public payload only once the members' copy is refused.
- **2026-09-28** The lost-verification notification is app-only in PR 1. The mail comes with FID claims in PR 2, which needs a mailer anyway.
- **2026-09-28** The data migration cannot reach RSI, so SID-shaped values that RSI answers with 404 are kept. They stay unverified and hidden publicly.

## Progress
- [x] Phase 1 — normalise `rsi_sid`
- [x] Phase 2 — verification model and job
- [x] Phase 3 — API
- [x] Phase 4 — frontend
- [ ] PR 2 — FID claims
