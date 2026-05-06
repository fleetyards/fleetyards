# Discord scheduled-events sync — operations

Fleetyards mirrors fleet events to Discord guild scheduled events and pulls
RSVPs back. This doc covers everything you need to get a fresh environment
talking to Discord, plus the moving pieces in case something breaks.

## Architecture in one paragraph

Two paths, both pivoting on the `discord_event_id` column on `fleet_events`.

**Push** is HTTP-only and runs on the web/sidekiq tier:
`AS::Notifications` (`fleet_event.{published,locked,…,destroyed}`) →
`Notifications::Discord::FleetEventSubscriber` → `Discord::SyncFleetEventJob`
→ `Discord::ScheduledEventSync` → `Discord::ApiClient` → Discord REST API.

**Pull** runs in a separate long-lived process (`bin/discord-bot`) holding
a Gateway websocket. `discordrb` dispatches
`scheduled_event_user_register` / `scheduled_event_user_unregister`
events into `Discord::ScheduledEventRsvpHandler`, which maps the Discord
user → FY user via `OmniauthConnection(provider: "discord")` and the
guild scheduled event → FY event via `discord_event_id`, then
creates/withdraws a slot-less `FleetEventSignup`.

A single Discord application drives both halves: the same bot token is
used for HTTP pushes and Gateway pulls.

## One-time Discord application setup

Per environment (prod and stage need separate applications, otherwise the
Gateway sessions fight each other).

1. https://discord.com/developers/applications → **New Application**.
   Name it `Fleetyards` for prod, `Fleetyards Stage` for stage.
2. Sidebar → **Bot** → **Reset Token** → copy.
   Store under 1Password vault `Fleetyards`:
   - prod: item `DISCORD_BOT_LIVE`, key `credential`
   - stage: item `DISCORD_BOT_STAGE`, key `credential`
   The Kamal secrets file pulls these via `op read` automatically — see
   `.kamal/secrets.live` and `.kamal/secrets.stage`.
3. **Privileged Gateway Intents** — leave them all off. The portal only
   exposes the privileged intents (Presence, Server Members, Message
   Content). The bot needs `GUILDS` and `GUILD_SCHEDULED_EVENTS`, both
   non-privileged — those don't appear in the portal at all and are
   requested from `bin/discord-bot` via
   `intents: %i[servers server_scheduled_events]`. No portal action
   needed for them.
4. Toggle **Public Bot** off so it can't be added to random servers.
5. Sidebar → **Installation** → **Install Link** → **Discord Provided
   Link**. Default Install Settings:
   - Scopes: `bot`, `applications.commands`
   - Bot Permissions: `Manage Events` (only)

   Copy the install URL. This is what fleet admins click to add the bot
   to their server.

## Local development

Use the prod or stage bot here only if no real fleet has it installed —
otherwise you'll fight with the live Gateway session. Use the dedicated
`Fleetyards Dev` application + a personal test Discord server.

The dev bot's token lives in 1Password under `DISCORD_BOT_DEV/credential`
and is referenced from `.env.tpl` as
`DISCORD_BOT_TOKEN=op://Fleetyards/DISCORD_BOT_DEV/credential`. Render
your `.env.local` with the usual `op inject` flow you already use for the
other dev secrets, then:

```bash
# Terminal 1: web + sidekiq via your usual command
bin/dev

# Terminal 2: the bot, with the rendered env loaded
bundle exec ruby bin/discord-bot
# expect: [discord-bot] starting Gateway listener
#         (then a few discordrb log lines about connecting)
```

In Discord:
1. Add the bot to a personal test server using the install URL.
2. Server Settings → Advanced → enable Developer Mode.
3. Right-click the server name → Copy Server ID.

In Fleetyards:
1. Make sure your test user has Discord linked under `/settings/connections`
   — the bot uses `OmniauthConnection` to map RSVPs back.
2. Fleet → Settings → Notification Settings.
3. Paste the server ID, optionally a voice channel ID, save.
4. Click **Test Discord connection** — should show a green check + the
   server name. If not, the error pill tells you which step to revisit.
5. Toggle which Discord events you want to mirror (publish / cancel / etc).
6. Publish a test event. It should appear in the server's *Events* tab
   within a few seconds. Click *Interested* in Discord — bot logs
   `[discord-bot] add … ok (created event-level signup)`, signup shows
   up on Fleetyards.

## Deploying

Already wired in `config/deploy.yml`. The `discord_bot` role:
- Runs `bundle exec ruby bin/discord-bot` under Kamal.
- 512 MB memory cap.
- Pinned to a single host (default: the primary web host, override via
  `KAMAL_DISCORD_BOT_HOST`). **Do not scale this past 1** — Discord
  rejects the second Gateway connection per application and the bot
  silently restarts in a tight loop.
- `DISCORD_BOT_TOKEN` flows through `env.secret`.

Deploy as usual:

```bash
kamal deploy -d live   # or -d stage
kamal app logs --roles=discord_bot --follow
```

## Per-fleet onboarding (what fleet admins do)

1. Click the install URL provided by their Fleetyards admin → pick their
   Discord server → Authorize.
2. Discord Settings → Advanced → enable Developer Mode (one-time).
3. Right-click their server name → Copy Server ID. Optionally do the
   same on a voice channel if they want events anchored there.
4. Fleetyards → fleet → Settings → Notification Settings → paste the
   IDs → **Test Discord connection** → save.

The "Test Discord connection" button hits
`GET /fleets/:slug/notifications/discord-status`, which probes
`GET /guilds/{id}` with the bot token. Codes mapped to friendly errors:

| Code | Cause | Fix |
|------|-------|-----|
| `missing_token` | Server-side env not set | Ops issue — check Kamal secrets / `DISCORD_BOT_TOKEN` |
| `missing_guild` | No `discord_guild_id` saved yet | Paste it and save |
| `invalid_token` | Token rotated / wrong | Re-rotate in Discord dev portal, update 1Password |
| `bot_not_in_guild` | Server admin removed the bot | Re-run the install URL |
| `guild_not_found` | Wrong server ID | Re-copy from Discord with Developer Mode on |
| `discord_error` | Anything else (rate limit, 5xx) | Look at Discord status page; retry |

## What lives where

- `lib/discord/api_client.rb` — Faraday wrapper, bot-token auth,
  retry on 429/5xx.
- `lib/discord/scheduled_event_sync.rb` — idempotent FY event ↔
  Discord scheduled event mapping. Handles 404 stale-id recovery.
- `lib/discord/scheduled_event_rsvp_handler.rb` — pure-AR mapping for
  RSVP add/remove. Unit-tested without any Gateway.
- `app/jobs/discord/sync_fleet_event_job.rb` — Sidekiq job, queue
  `notifications`, retries on 429 / 5xx only.
- `app/lib/notifications/discord/fleet_event_subscriber.rb` —
  AS::Notifications subscriber that gates on
  `Discord::ApiClient.configured?` AND `discord_guild_id` present.
- `bin/discord-bot` — the long-running process. Routes
  `scheduled_event_user_register` / `unregister` to the handler.
  Catches all errors so a bad event doesn't crash the loop.
- `app/controllers/api/v1/fleet_notification_settings_controller.rb` —
  show/update/discord-status endpoints.

## Failure-mode quick reference

**Push silently doesn't fire.** Check
`Discord::ApiClient.configured?` and `fleet.fleet_notification_setting&.discord_guild_id`.
The subscriber gates on both before enqueueing the job.

**Push enqueues but Discord shows nothing.** Sidekiq logs will show the
failed job. The most common reasons: bot was removed from the guild
(`403 Missing Access`), or wrong guild id was saved (`404 Unknown Guild`).
The job retries 3 times via Sidekiq `retry: 3`.

**Bot keeps restarting.** Check there's only one `discord_bot` replica
(`kamal details --roles=discord_bot`). Two replicas with the same token
fight for the Gateway session.

**RSVPs don't reach FY.** In order: bot logs (`kamal app logs --roles=discord_bot --follow`), then check that the RSVPing user has Discord linked on FY (`OmniauthConnection`), then check that they're an accepted member of the fleet. The handler skips silently for any missing prerequisite — log line tells you which.

**Token rotated, urgent.** Update the 1Password entry, run
`kamal env push --roles=discord_bot` to re-deploy just the env, then
`kamal app boot --roles=discord_bot` to restart. The web/worker tier
also has the env but doesn't currently use the rotated token until
the next push fires, so order doesn't matter much.

## Related smoke tests

```bash
# Verify token is loaded
bundle exec rails runner 'puts Discord::ApiClient.configured?'

# Manually probe a guild (replace the ID)
bundle exec rails runner 'pp Discord::ApiClient.new.get_guild("123456789012345678")'

# Force a sync for a specific event
bundle exec rails runner '
  event = FleetEvent.find_by(slug: "abc123-strike-op")
  Discord::ScheduledEventSync.new(event).upsert!
'

# Run the bot locally without Kamal
bundle exec ruby bin/discord-bot
```
