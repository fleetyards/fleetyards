# Let fleet officers map fleet roles to Discord roles

Working plan for #5174. Decisions live in the issue body. Deleted before the PR merges.

Stacked on #5484 (`feat/5478-join-fleet-through-discord-role`), which adds `GET /fleets/:slug/discord-roles`, `Discord::GuildRoles`, `FleetDiscordRolePolicy` (allows `fleet:notifications:manage`) and `DiscordRoleSelect`. The PR targets that branch until it merges.

## Goal
Officers can pick, from the bound guild's roles, which Discord role each fleet role grants, and changing or clearing a mapping is reflected on members' Discord roles.

## Open questions
- None. Privilege, UI location and the member role are decided in the issue body. The permanent Admin role is mappable like any other rank.

## What changed

### Phase 1 — Clearing a mapping removes the role
`MemberRoleSync#managed_role_ids` is computed from current mappings only, so a role that was mapped X → nil (or X → Y) is never removed.
1. `FleetRole#backfill_discord_member_roles` passes the previous `discord_role_id` (from `saved_change_to_discord_role_id`) to `BackfillFleetMemberRolesJob` as a third positional arg.
2. The backfill job forwards it to `SyncMemberRolesJob`; `MemberRoleSync` takes `retired_role_ids:` and adds them to `managed_role_ids` (so `runnable?` holds when the last mapping is cleared). `desired_role_ids` and `owed_in_guild` still protect a role another rank or fleet still owes.
3. Same for `FleetNotificationSetting#discord_member_role_id` changes (whole-fleet backfill).
4. Snowflake validation on `FleetRole#discord_role_id` (mirror `FleetNotificationSetting::DISCORD_ID_ATTRIBUTES`).

### Phase 2 — API
1. `GET /fleets/:slug/discord-role-mappings`: every fleet role with its `discordRoleId`, gated on `FleetNotificationSettingPolicy#show?`. Not added to the public fleet roles index, which every member can read.
2. `PUT /fleets/:slug/discord-role-mappings` with `{ mappings: [{ fleetRoleId, discordRoleId }] }` (an `Input` component). Same gate. Updates each role in one transaction, so each changed rank's after_commit backfill fires.
3. The member role keeps its existing path: `PUT /fleets/:slug/notifications` already permits `discord_member_role_id`.
4. Integration tests first, then `./bin/generate-schema` and `bin/generate-clients`.

### Phase 3 — Frontend
1. A "Role mapping" section on `settings/discord.vue`: a `DiscordRoleSelect` (from #5484) for the member role, then one per fleet role in rank order.
2. Save sends the member role through the existing settings payload and the rank mappings through the new endpoint, only when they changed.
3. Show `rolesCode`/`rolesDetail` from the status probe, so the fleet sees when the bot can't manage a mapped role.
4. Labels in all 7 locales, and Vitest specs for the page.

## Intent Verification

- [x] **Officers with the right privilege pick a Discord role per fleet role from the bound guild's roles** — request test for the roles list and the update; UI shows guild roles in the picker.
- [x] **Changing a mapping re-syncs affected members** — job test: update enqueues the rank-scoped backfill (already wired; keep covered).
- [x] **Clearing a mapping removes that managed role on the next sync** — `MemberRoleSync` test: X → nil removes X from a member who holds it; X stays when another rank or fleet in the guild still maps it.
- [x] Members without the privilege get 403 on both endpoints.

## Key files

| File | Role |
|------|------|
| `lib/discord/member_role_sync.rb` | Computes add/remove; needs retired role ids |
| `app/jobs/discord/backfill_fleet_member_roles_job.rb` | Rank-scoped re-sync after a mapping change |
| `app/jobs/discord/sync_member_roles_job.rb` | Per-membership sync |
| `app/models/fleet_role.rb` | `discord_role_id`, after_commit trigger |
| `app/models/fleet_notification_setting.rb` | Guild binding, member role |
| `lib/discord/api_client.rb` | `get_guild_roles` already exists |
| `lib/discord/role_capability.rb` | Explains roles the bot cannot manage |
| `app/controllers/api/v1/fleet_roles_controller.rb` | `update` permits only `name` today |
| `app/policies/fleet_role_policy.rb`, `fleet_notification_setting_policy.rb` | Privilege gates |
| `config/routes/api/fleets_routes.rb` | `discord-channels` route to sit beside |
| `app/frontend/frontend/pages/fleets/[slug]/settings/discord.vue` | Discord settings page |
| `app/frontend/frontend/components/Fleets/DiscordRoleSelect/index.vue` | Picker (from #5484) |

## Not in scope (deferred)
- **Caching guild roles** — nothing in `lib/discord` caches; channels are fetched live too. Drop.
- **Roles left behind on a server switch** — a new server clears every mapping with `update_all`, and the old server's roles stay on members there. The sync only talks to the bound server, so it cannot reach them. Drop unless someone asks.

## Discovery Log

- **2026-10-08** Initial research. `fleet_roles` already has an `update` route (name only). Criterion 2 is already wired at the model level (`FleetRole` after_commit → rank-scoped backfill). Criterion 3 is not: cleared mappings drop out of `managed_role_ids`. `ApiClient#get_guild_roles` exists; the discord status probe already returns `roles*` fields the frontend ignores.
- **2026-10-08** #5484 already ships the guild role list and picker, so this branch stacks on it.
- **2026-10-08** The factory's officer rank does not hold `fleet:notifications:manage`; tests use a rank with exactly that privilege. Rank mapping is read through its own endpoint so the roles index, readable by every member, does not change.

## Progress
- [x] Phase 1 — clearing removes the role
- [x] Phase 2 — API
- [x] Phase 3 — Frontend
- [ ] PR opened and reviewed
