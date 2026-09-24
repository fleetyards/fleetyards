# Discord Unlink Removes Roles

## Goal
Unlinking a Discord account takes every fleet-managed role off that Discord
account in every fleet the member belongs to, and leaves every role the fleet
hands out by hand alone.

## Context
`OmniauthConnection` backfills a member's roles when Discord is linked
(`after_create_commit :backfill_discord_member_roles`) but had no destroy hook.
`Discord::MemberRoleSync` resolves the Discord uid through the user's current
connection, so once the connection is gone no sync can reach that account
again, and every managed role it was given stays on it.

Resolves #5160

## Decisions

### D1 — Capture the uid at destroy time and hand it to the job
The job must not reload the destroyed connection. `after_destroy_commit`
enqueues `Discord::RevokeUserMemberRolesJob.perform_async(user_id, uid)`; the
record's attributes are still readable in the callback.

### D2 — Reuse `MemberRoleSync` with a revoke mode
`MemberRoleSync.new(membership, discord_uid:, revoke: true)` sets the desired
roles to none. Removal is still `managed_role_ids & current`, so the invariant
that only fleet-configured roles are ever touched holds without a second code
path.

### D3 — Every membership, in any state
The job walks all of the user's memberships, not only accepted ones. For a
non-accepted membership the normal sync already removed the roles, so the pass
is a no-op there, and it is correct if one was missed.

### D4 — Skip when the same account is linked again
If the member relinks the same uid before the job runs, the backfill owns that
account again and the revoke would fight it, so the job returns early. A
relink that lands while the job runs is caught by a second check at the end,
which enqueues `BackfillUserMemberRolesJob` so the new link's roles are put
back.

### D5 — Errors are handled per membership
A permanent API error in one fleet (400, 403, 404) is logged and skipped so
the other fleets are still revoked. 429 and 5xx are re-raised for a Sidekiq
retry; the revoke is idempotent, so redoing fleets that already succeeded is
harmless.

## What changed
1. `lib/discord/member_role_sync.rb` — `discord_uid:` and `revoke:` options.
2. `app/jobs/discord/revoke_user_member_roles_job.rb` — new job.
3. `app/models/omniauth_connection.rb` — `after_destroy_commit` for Discord.
4. Tests: revoke mode in `test/lib/discord/member_role_sync_test.rb`, the job
   and the destroy trigger in `test/jobs/discord/revoke_user_member_roles_job_test.rb`,
   and the unlink endpoint enqueuing it in
   `test/integration/api/v1/omniauth_connections_test.rb`.

## Intent Verification
- [x] Destroying a Discord connection enqueues the revoke with the old uid
- [x] Managed member and rank roles are removed in every fleet with a guild
- [x] A role the fleet did not configure is never removed
- [x] Other providers enqueue nothing; relinking the same uid skips the revoke
- [x] One fleet's permanent error does not stop the others; a mid-run relink is backfilled

## Key files
| File | Role |
|------|------|
| `lib/discord/member_role_sync.rb` | Computes and applies role changes; the managed-roles invariant |
| `app/jobs/discord/revoke_user_member_roles_job.rb` | Runs the revoke per membership |
| `app/jobs/discord/backfill_user_member_roles_job.rb` | The link-side counterpart |
| `app/models/omniauth_connection.rb` | Create and destroy hooks |

## Not in scope
- **Account deletion** — `User` destroys its memberships before its
  connections, so the job finds no memberships for a deleted user.

## Progress
- [x] Revoke mode on `MemberRoleSync`
- [x] Revoke job and destroy hook
- [x] Tests
