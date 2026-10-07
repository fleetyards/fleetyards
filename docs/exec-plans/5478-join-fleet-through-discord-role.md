# Join a fleet through a role in its Discord server

Working plan for #5478. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fleet can name a role in its bound Discord guild; a player whose linked Discord account holds it becomes an accepted member with the fleet's default role, without an approval step, and losing it ends that membership.

## Open questions
- None. Ops step before deploy: enable the Server Members intent for the bot in the Discord developer portal. With the intent requested but not enabled, the Gateway refuses the connection and the scheduled-event RSVP sync stops too.

## What changed

### Phase 1 — Setting and role list
1. `fleet_notification_settings.discord_join_role_id`, validated as a snowflake.
2. Changing it needs `fleet:manage` / `fleet:invites:manage` / `fleet:invites:create` (`FleetNotificationSettingPolicy#update_join_role?`); resending the current value does not.
3. `GET /fleets/:slug/discord-roles` (`Discord::GuildRoles`), without @everyone and managed roles, highest first.

### Phase 2 — Membership
1. `fleet_memberships.discord_role_granted` marks memberships the role created; only those are ended by Discord.
2. `fleet_discord_role_holders` records who held the role when last seen, so membership follows changes to the role (`FleetDiscordRoleHolder.remember` / `forget` decide which event acts).
3. `Discord::JoinRole`: `held_by?` (join time), `apply(user, role_ids)` (gain admits, loss releases), `member_changed` (Gateway entry point).
4. New AASM event `join` (created → accepted), notifying admins and the member through the existing accepted notifications.
5. Triggers: invite link use and sign-up with an invite (`request_or_join!`), Discord link (`ApplyJoinRolesJob`), role picked or guild changed (`SyncFleetJoinRoleJob` with reset), daily sweep (`SyncJoinRolesDispatchJob`), Gateway `GUILD_MEMBER_UPDATE` / `GUILD_MEMBER_REMOVE` in `bin/discord-bot`.

### Phase 3 — Frontend
1. `DiscordRoleSelect` on the fleet's Discord settings, shown only with the `createInvites` capability; the field is only sent then.
2. Four labels in all 7 locales.

## Intent Verification

- [x] **Setting** — A fleet can pick a role in its bound guild; none is set by default.
- [x] **Direct membership** — A holder becomes an accepted member with the default member role (`join_role_test`, `fleets_invite_urls_use_test`).
- [x] **Removal** — Losing the role or leaving the guild ends a role-granted membership; hand-approved members stay.
- [x] **Fallback** — A player without the role still gets a request.
- [x] **Privilege** — Only invite-privileged members can change the role (`fleets_notifications_update_behaviour_test`).
- [x] **Translations** — de, en, es, fr, it, zh-CN, zh-TW.

## Key files

| File | Role |
|------|------|
| `lib/discord/join_role.rb` | held check, gain/loss application |
| `app/models/fleet_discord_role_holder.rb` | last-seen holders |
| `app/models/fleet_membership.rb` | `join` event, `request_or_join!` |
| `app/jobs/discord/apply_join_roles_job.rb` | one Discord user, re-reads their roles |
| `app/jobs/discord/sync_fleet_join_role_job.rb` | whole guild, paged |
| `bin/discord-bot` | Gateway member events |
| `lib/discord/guild_roles.rb` | role list for the picker |
| `app/frontend/frontend/components/Fleets/DiscordRoleSelect/index.vue` | picker |

## Not in scope (deferred)
- **Mapping fleet roles to Discord roles (#5174)** — can reuse the role list endpoint and `DiscordRoleSelect`.
- **Ask to join from the public fleet page (#5377)** — should call `request_or_join!` instead of `request!`.

## Discovery Log

- **2026-10-08** Initial research. #5174 and #5377 are still open; no guild-role picker or lister existed.
- **2026-10-08** `bin/discord-bot` already runs a Gateway listener for scheduled-event RSVPs; member events go through it. Needs the privileged Server Members intent.
- **2026-10-08** `FleetMembershipsController#create_by_invite` has no route; left alone.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
