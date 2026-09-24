# Fleets: a Discord channel per squadron for squadron events

## Goal
A squadron can pick a text channel on the fleet's bound Discord server. Its events are announced there and nowhere else on Discord. Every fleet event gets a published post and a starting-soon post, and the fleet can set a weekly digest.

## Context
Events, contracts and inventories can be held to squadrons (D19 in `docs/exec-plans/fleet-squadrons.md`). In-app announcements already narrow to the squadron. Discord cannot be narrowed yet: the fleet has one guild binding and one reminder webhook, and both reach the whole fleet. So squadron events are kept off Discord. `SyncFleetEventJob` turns an upsert into a delete, `fleet_event.restricted` takes a posted event down, and `AnnounceEventReminderJob` returns early.

This plan lifts that gate for squadrons that have a channel. The issue settles on a channel per squadron, on the fleet's own server, posted through the bot the fleet already installed.

Resolves #5157

## Decisions

### D1 — One `discord_channel_id` column on `fleet_squadrons`
A nullable string column holds a channel id from the fleet's bound guild (`FleetNotificationSetting#discord_guild_id`).

Teams are `fleet_squadrons.team = true` and not a separate model. They get a channel too, as the issue asked.

The column is set through the existing squadron update. It is permitted in `FleetSquadronPolicy#params_filter`, so whoever may update the squadron manages it. It is exposed in the member-facing `FleetSquadron` schema and never in the public views or the `FleetSquadronRef`.

### D2 — Squadron events stay off guild scheduled events
Discord's only privacy level for guild scheduled events is `GUILD_ONLY`, so everyone on the server sees them. There is no per-event audience.

A squadron event is therefore never a guild scheduled event. It is announced only in its squadrons' channels. The existing skip in `SyncFleetEventJob` and the `fleet_event.restricted` takedown stay.

The skip also closes two gaps found while researching:
- The manual `FleetEventsController#sync_to_discord` pushes squadron events anyway.
- The restricted takedown ignores per-occurrence `discord_event_id`s on recurring events.

### D3 — Posts go through the bot, never the webhook
Squadron posts use `Discord::ApiClient#create_message(channel_id, payload)`, following the `Discord::DirectMessage` pattern. The content reuses `Discord::EventReminder` / `EventAvailability` for title, message and URL.

There is no fallback. A squadron without a channel gets no post, and the fleet channel or webhook is never used. An event held to several squadrons posts once to each distinct channel. Two squadrons that share a channel get a single post.

### D4 — What gets posted, for every event
Three announcements, for fleet-wide and squadron events alike:
- **published:** a message when an event is published. An edit that restricts an already-published event to squadrons also posts it to their channels.
- **starting soon:** the existing `fleet_event.starting_soon` reminder, which `Notifications::FleetEventStartingSoonJob` fires every 5 minutes. It is deduplicated per occurrence by `starting_soon_notified_at`.
- **weekly digest:** see D10.

Cancellations are not announced. Edits to time or place after publishing are not re-announced.

### D9 — Fleet-wide events post to a fleet announcement channel
A new `fleet_notification_settings.discord_announcement_channel_id` column holds a text channel. It is chosen with the same picker as the squadrons use, and the bot posts fleet-wide events there.

`discord_channel_id` stays as the voice channel for guild scheduled events. It does not become the text channel.

Existing fleets keep working. With no announcement channel set, the published and starting-soon posts for fleet-wide events go through `discord_webhook_url`, as the reminder does today. Once a channel is set, the bot is used and the webhook is ignored.

Squadron events never go to the fleet channel or the webhook (D3). Fleet-wide events keep their guild scheduled event.

### D10 — Weekly digest, one schedule per fleet
The fleet's Discord settings gain `discord_digest_weekday` (0–6, nullable, off by default) and `discord_digest_time` ("HH:MM"). Both are read in `fleets.default_timezone`.

At that time, each channel gets one post listing the events of the coming seven days that it may see:
- the fleet channel, or the webhook as a fallback, lists fleet-wide events
- each squadron channel lists the events held to that squadron

A channel with nothing in the week posts nothing. Recurring events contribute each occurrence in the window, which `FleetEvent#occurrences` already expands.

`Discord::WeeklyDigestDispatchJob` runs every 15 minutes from `config/sidekiq_schedule.yml`, gated on `ApiClient.configured?` like the RSVP poll. It picks fleets whose weekday and time fall due. A `discord_digest_sent_at` stamp makes a slow or repeated run post at most once a week.

### D5 — Bot permissions: Send Messages + Embed Links
`ApiClient::INSTALL_PERMISSIONS` lacks Send Messages (1<<11) and Embed Links (1<<14), so the mask needs both bits added. Existing installs keep their old grant.

A `Discord::ChannelCapability` check, modelled on `RoleCapability`, reports whether the bot can post to a given channel. The Discord settings page then tells the fleet to re-authorise, the same way it does for roles.

### D6 — Channel picker from the guild's channel list
A new `ApiClient#get_guild_channels(guild_id)` lists the guild's channels. A new endpoint, `GET fleets/:slug/discord-channels`, returns the text and announcement channels (types 0 and 5) as `{ id, name, parentName }`.

The endpoint is authorised for anyone who may update a squadron in the fleet. A new `DiscordChannelSelect` component uses it, and the squadron form gets it as a "Discord" tab.

With no guild bound, the tab explains that and links to the Discord settings.

### D7 — A deleted channel is checked live, not persisted
When the squadron edit page and the settings list load, the channel id is checked against `get_guild_channels`. A missing channel shows as "channel no longer exists on Discord". No flag is stored, so the state heals itself if the channel is re-picked.

Posting treats 403, 404 and Discord code 10003 as "post nothing". It logs and skips, like `DirectMessage`, and never retries.

### D8 — Event form warning from data already loaded
`SquadronSelect` already loads the fleet's squadrons with `perPage: "all"`. Once they carry `discordChannelId`, `signup.vue` can list the selected squadrons without one, next to the select. The same warning is shared with `ContractForm` and `InventoryModal` only where Discord applies, which is events.

The warning also shows when the fleet has no guild bound at all. It covers only a missing setting, not a deleted channel, which is D7's job on the squadron side.

## What changed

### Phase 1 — Data and API
1. Migration: add `fleet_squadrons.discord_channel_id` (string, nullable).
2. Add the column to `FleetSquadronPolicy#params_filter`, the `_base.jbuilder` of the member views, and the `FleetSquadron`, `FleetSquadronCreateInput` and `FleetSquadronUpdateInput` schemas.
3. Add `ApiClient#get_guild_channels`, plus the `discord-channels` endpoint with its schema and integration test.
4. Run `bin/generate-schema` and `bin/generate-clients`.

### Phase 2 — Posting
1. `INSTALL_PERMISSIONS` gains Send Messages and Embed Links. Add `Discord::ChannelCapability` and surface it in `discord_status`.
2. Add `fleet_notification_settings.discord_announcement_channel_id` (D9) to the settings schema, the policy and the view.
3. `Discord::EventAnnouncement.targets(event)` resolves the post targets:
   - a squadron event goes to its squadrons' distinct channels
   - a fleet-wide event goes to the announcement channel, or to the webhook when none is set
4. `Discord::ChannelPost` posts through the bot and rescues 403/404/10003.
5. `AnnounceEventReminderJob` goes through the targets instead of returning early for squadron events.
6. Add a `Discord::AnnounceEventPublishedJob`, wired to `fleet_event.published` and `fleet_event.restricted` in the Discord fleet event subscriber.
7. `sync_to_discord` refuses squadron events. The restricted takedown also deletes the occurrence-level guild events.

### Phase 3 — Weekly digest
1. Add `discord_digest_weekday`, `discord_digest_time` and `discord_digest_sent_at` to `fleet_notification_settings`, and put the first two in the schema and the policy.
2. `Discord::WeeklyDigest` builds each channel's list for the next seven days.
3. `Discord::WeeklyDigestDispatchJob` runs every 15 minutes in `sidekiq_schedule.yml`.

### Phase 4 — Frontend
1. Add a `DiscordChannelSelect` component and a "Discord" tab in the squadron form, with the no-guild and deleted-channel states.
2. On `settings/discord.vue`, add the announcement channel picker and the digest weekday and time fields.
3. Add a channel status hint on `SquadronPanel` in the settings list.
4. Add the missing-channel warning beside `SquadronSelect` in `events/[event]/edit/signup.vue`.
5. Translate the new keys in every locale by hand.

### Phase 5 — `/fleetevents` leak
1. `lib/discord/commands/fleet_events.rb` lists squadron events to every member. Filter it with `for_squadrons_of` for the invoking member's membership.

## Intent Verification

- [ ] **Channel setting** — a squadron manager can pick a text channel from the fleet's bound guild, and someone without squadron update rights cannot
- [ ] **No fallback** — a squadron event whose squadrons have no channel posts nothing anywhere on Discord, including through the fleet webhook
- [ ] **Multi-squadron** — an event held to two squadrons with different channels posts to both, and one shared channel gets one post
- [ ] **No guild event** — a squadron event never becomes a guild scheduled event, including through the manual sync button
- [ ] **Deleted channel** — posting to a deleted channel posts nothing and does not raise, and the squadron's settings say the channel is gone
- [ ] **Event form warning** — picking a squadron without a channel names it beside the squadron picker
- [ ] **Permissions** — a fleet whose bot lacks Send Messages is told to re-authorise
- [ ] **Published** — publishing a fleet-wide event posts to the fleet announcement channel, or to the webhook when none is set, and publishing a squadron event posts to its squadrons' channels
- [ ] **Starting soon** — every event, squadron events included, gets exactly one starting-soon post per occurrence in its channels
- [ ] **Weekly digest** — at the fleet's chosen weekday and time, in the fleet's timezone, each channel gets one list of the next seven days' events it may see, and a second run the same week posts nothing
- [ ] **No cancel post** — cancelling an event posts nothing

## Key files

| File | Role |
|------|------|
| `app/models/fleet_squadron.rb` | Squadron model; new column |
| `app/policies/fleet_squadron_policy.rb` | `params_filter`, `update?` |
| `app/views/api/v1/fleet_squadrons/_base.jbuilder` | Member serialisation (cached fragment) |
| `app/api_components/v1/schemas/fleets/squadrons/fleet_squadron.rb` | Hand-written schema, `additionalProperties: false` |
| `app/api_components/v1/schemas/inputs/fleet_squadron_{create,update}_input.rb` | Input schemas |
| `lib/discord/api_client.rb` | `get_guild_channels`, `INSTALL_PERMISSIONS`, `create_message` |
| `lib/discord/role_capability.rb` | Pattern for `ChannelCapability` |
| `lib/discord/direct_message.rb` | Pattern for bot posting and rescuing 403/404 |
| `lib/discord/event_reminder.rb` | Reminder content to reuse |
| `app/jobs/discord/announce_event_reminder_job.rb` | Squadron skip at line 21 |
| `app/jobs/discord/sync_fleet_event_job.rb` | Guild-event skip at line 27 |
| `app/lib/notifications/discord/fleet_event_subscriber.rb` | Event wiring |
| `app/controllers/api/v1/fleet_events_controller.rb` | `sync_to_discord` gap, `fleet_event.restricted` |
| `app/controllers/api/v1/fleet_notification_settings_controller.rb` | `discord_status` |
| `app/frontend/frontend/composables/useSquadronForm.ts` | Squadron form payload |
| `app/frontend/frontend/pages/fleets/[slug]/squadrons/form/routes.ts` | Squadron form tabs |
| `app/frontend/frontend/pages/fleets/[slug]/events/[event]/edit/signup.vue` | Squadron picker; warning |
| `app/frontend/frontend/components/Fleets/Squadrons/SquadronSelect/index.vue` | Loads squadrons for the picker |
| `lib/discord/commands/fleet_events.rb` | `/fleetevents` leak |
| `app/models/fleet_notification_setting.rb` | Announcement channel and digest settings |
| `config/sidekiq_schedule.yml` | Digest dispatch cron |
| `app/jobs/notifications/fleet_event_starting_soon_job.rb` | Starting-soon trigger |
| `app/frontend/frontend/pages/fleets/[slug]/settings/discord.vue` | Fleet Discord settings |

## Not in scope (deferred)
- **Squadron channels for contracts and inventories.** Neither posts to Discord today.
- **Re-announcing edits.** Time and place changes after publish are not re-posted, matching today's webhook behaviour.
- **Role-gated channel creation.** Fleetyards picks an existing channel and never creates channels or sets their permissions.

## Discovery Log

- **2026-09-24** Initial research and plan creation. There is no guild channel list call and no channel picker today. `fleet_notification_settings.discord_channel_id` is the voice channel for guild events, not a text channel. The bot's install mask cannot send messages. The manual sync and the `/fleetevents` command both leak squadron events.
- **2026-09-24** Settled with the user:
  - teams get a channel too
  - every event gets a published post and a starting-soon post
  - the fleet sets one weekly digest day and time
  - cancellations are not posted
  - fleet-wide events go to a new fleet announcement channel, with the webhook as the fallback

## Progress
- [ ] Phase 1 — Data and API
- [ ] Phase 2 — Posting
- [ ] Phase 3 — Weekly digest
- [ ] Phase 4 — Frontend
- [ ] Phase 5 — `/fleetevents` leak
