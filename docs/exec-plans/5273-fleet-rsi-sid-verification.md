# Fleet RSI SID verification and FID claims

Working plan for #5273. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fleet verified for an RSI SID can claim the FID equal to that SID from whichever fleet holds it. The holder gets 14 days to prove the SID itself or tell its members; then it is renamed to the next free `X-N` and the claimant gets `X`.

PR 1 (normalisation and verification) merged as #5274. This branch is PR 2, FID claims, cut from `main`.

## Open questions
- None.

## Design

### Model: `FleetFidClaim` (`fleet_fid_claims`)
- `claimant_id` (fleet, cascade), `holder_id` (fleet, nullify), `created_by` (user), `fid` (the SID, uppercase).
- `state`: `open`, `completed`, `cancelled`. `cancel_reason`: `withdrawn`, `holder_verified`, `claimant_unverified`, `admin`.
- `ends_at`, `completed_at`, `cancelled_at`, `holder_previous_fid`, `holder_new_fid`.
- Partial unique index on `fid` where `state = 'open'`; index on `(state, ends_at)`.

### Rules
- Claimable when the fleet is verified, its verified SID is a valid FID (3+ characters), it does not already hold that FID, and another kept fleet does.
- If nobody holds it, the fleet can simply set its FID; there is nothing to claim.
- An FID with an open claim is reserved: only the claimant may take it, and the holder cannot rename back to it after leaving it.
- Cancelled when the claimant loses its verification: a takeover (reason `holder_verified` when the holder is the new verifier), an admin revoke, or discarding the claimant.
- Completion rechecks everything under locks: the claimant must still be kept and verified for the FID. The current holder, if any, is renamed to the next free `X-N`, and then the claimant takes `X`.
- A cron sweep completes due claims every 10 minutes. An admin who shortens a claim to now also enqueues the sweep.

### Notifications
- `fleet_fid_claim_opened` goes to the holder's managers. `fleet_fid_claim_completed` and `fleet_fid_claim_cancelled` go to both sides (a claimant that withdrew is not told). All three use app and mail.
- `fleet_rsi_verification_lost` gains mail, as the issue decided.
- `FleetMailer.notification` is one generic template: title, body, and a button to the link.

### API
- `GET/POST/DELETE /fleets/:slug/fid-claim` (`fleet:manage`): the status for the fleet (`availability`, claimable `fid`, `outgoing` and `incoming` claims), open a claim, withdraw one.
- `POST /fleets/check` answers with `FleetFidCheck` (`taken`, plus `suggestion` when a taken value is shaped like an SID).
- `FleetCreateInput` accepts `rsiSid`.
- Admin: `GET /fleet-fid-claims` (open claims), `PATCH /fleet-fid-claims/:id` (`endsAt`, earlier only), `PUT /fleet-fid-claims/:id/cancel`.

### Frontend
- `settings/rsi.vue`: a claim panel for the claimant (claim, pending, withdraw) and a danger alert for the holder.
- Fleet page: the holder's managers see the incoming claim in place of the at-risk warning.
- `add.vue`: when a taken FID looks like an SID, explain claiming and offer `X-N` with the SID prefilled; after creation, open the RSI settings.
- Admin: `fleets/fid-claims/` list with end-now, set-date and cancel actions, linked from the fleets index.
- All labels in 7 locales.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_fid_claim.rb` | claim lifecycle |
| `app/models/fleet.rb` | reservation validation, `next_free_fid` |
| `app/lib/fleet_rsi_verification.rb` | cancel on takeover |
| `app/jobs/fleet_fid_claims_complete_job.rb` | sweep |
| `app/controllers/api/v1/fleet_fid_claims_controller.rb` | fleet API |
| `app/controllers/admin/api/v1/fleet_fid_claims_controller.rb` | admin API |
| `app/mailers/fleet_mailer.rb` | notification mail |

## Intent Verification

- [ ] A verified fleet claims its SID's FID; the holder's managers get an app notification and a mail.
- [ ] Only the verified SID can be claimed: no body parameter, and each non-claimable state answers 400.
- [ ] Completion renames the holder to `X-1` (or the next free suffix) and gives the claimant `X`; both are notified.
- [ ] The holder verifying the SID during the grace period cancels the claim, and so does a revoke.
- [ ] While a claim is open, no other fleet can register the FID.
- [ ] Admin lists open claims, shortens one and cancels one.
- [ ] Creating a fleet with a taken SID-shaped FID suggests `X-N` with the SID prefilled.

## Not in scope (deferred)
- **Public fleet directory**: its own issue; `listed` opt-in, verified, at least 2 accepted members.

## Discovery Log

- **2026-09-29** The PR 1 plan landed on `main` with #5274 instead of being deleted. This branch reuses it and deletes it before merge.
- **2026-09-29** An outsider hitting a fleet endpoint gets 404 from `authorized_scope`, not 403, so the 403 cases use a member without `fleet:manage`.
- **2026-09-29** The admin claim components are `AdminFleetFidClaim(s)`: a second `FleetFidClaim` component would exist in both documents.
- **2026-09-29** The admin page offers "end now" and cancel. Any earlier date works through `PATCH`, but a date picker was not worth its weight for a rare admin action.

## Progress
- [x] PR 1: normalisation and verification (#5274)
- [x] Model, migration, completion, cancellation
- [x] Notifications and mailer
- [x] API and schema
- [x] Frontend
- [x] Admin
