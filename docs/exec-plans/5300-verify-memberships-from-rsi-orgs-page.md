# Verify fleet memberships from the RSI organisations page

Working plan for #5300. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every user with a verified handle has a stored list of their visible RSI orgs, read from their organisations page or Citizen iD's claim. Their memberships' `verified` flags are derived from that list.

Stacked on #5294 (`feat/5293-verify-rsi-handle-via-profile-bio`) until it merges.

## Open questions
- None.

## What changed

### Phase 1 — The list and the flags derived from it
1. Migration: add `users.rsi_organization_sids` (a string array), `rsi_organizations_checked_at` (when a read was stored) and `rsi_organizations_attempted_at` (when one was last tried, for scheduling). Seed each list from the user's currently verified memberships.
2. `User#store_rsi_organizations(sids, read_at:, handle:)`, under a lock. It refuses a read older than the stored one, and one made through a handle that is no longer this account's verified handle. It then recomputes the user's memberships.
3. Losing, revoking or changing the handle empties the list and recomputes the memberships. That includes the accounts a takeover releases, and the revoke takes the same lock as a read.
4. `FleetMembershipVerification.verified?` requires a verified handle and the fleet's SID in the list. `sync_user` and `sync_fleet` write only the flags that change, through the model, so rosters get broadcasts. A new membership takes its flag from the list, and a fleet's SID change recomputes its members.
5. Citizen iD sign-in stores its claim as the list. A disconnect needs no membership step of its own.

### Phase 2 — Reading the page
1. `Rsi::CitizenOrganizationsPage` reads the visible org blocks only. A 403 is logged and reported as `:blocked`.
2. `UserRsiOrganizations` takes the read time before fetching, records every attempt except a block, and stores the list on success. `UserRsiOrganizationsJob` runs it after a successful bio verification.
3. `RsiOrganizationsRefreshJob` runs hourly over every user with a verified handle, least recently attempted first, a 24th of them per run. A block pauses it until the next day.

### Phase 3 — API and UI
1. `verificationCheckedAt` on the member payload comes from the user's list. The member and invite cache keys include the flag and the list's read time, to the microsecond.
2. The shield tooltip says when the list was last read, and ticks every minute.

## Not in scope (deferred)
- None.

## Discovery Log

- **2026-09-29** The organisations page marks each org block `visibility-V`, `-R` or `-H`, and the SID is the `.value` of the entry labelled "Spectrum Identification (SID)".
- **2026-09-29** The first version stored a source and a check time on each membership. The Devin review of #5302 found overlapping reads and clearing races that a per-user list avoids, so we reworked it (see the issue decisions). The dump has about 1,270 users with a verified handle, and 143 of them get a seeded list.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
