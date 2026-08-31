# Discord Bot

Fleetyards has had a Discord presence for years, but it only ever *pushes*: five webhook posters (`lib/discord/new_ship.rb`, `new_supporter.rb`, `rsi_news.rb`, `ship_on_sale.rb`, `youtube_video.rb`) and a one-way event sync (`lib/discord/scheduled_event_sync.rb`). Nobody in a Discord server can ask Fleetyards anything, and nothing a member does in Discord reaches Fleetyards.

This plan turns the app into a bot that answers and listens, in six phases that each ship on their own.

## The half-finished feature we already own

`lib/discord/scheduled_event_rsvp_handler.rb` is complete. It maps a Discord user to a Fleetyards user through `OmniauthConnection`, finds the `FleetEvent` by the stored `discord_event_id`, creates a slot-less `interested` signup, and — carefully — refuses to downgrade a stronger commitment made on Fleetyards, in both directions.

Nothing calls it. It was written for `GUILD_SCHEDULED_EVENT_USER_ADD` / `_REMOVE`, which are **Gateway** events, and this app has no Gateway process: the only `discordrb` require in the tree is `discordrb/webhooks` (`lib/discord/webhook.rb:3`). So "Interested" in Discord never arrives.

That shapes the whole plan. See Phase 3 — the fix is not a Gateway process.

## Foundation: HTTP interactions, not a Gateway

Slash commands do **not** need a persistent connection. Discord will POST every interaction to an **Interactions Endpoint URL**, and a plain Rails controller can answer it. That matters here because a Gateway bot is a new long-running process to deploy, supervise and scale under Kamal, for which this repo has no pattern — whereas an HTTP endpoint is a route, a controller and a Sidekiq job, all of which it has many patterns for.

Consequences of that choice, all of them acceptable:

- Commands work. Message content, presence, reactions and Gateway-only events do not. Only Phase 3 wanted one of those, and it has another route.
- Discord requires a response within **3 seconds** or the interaction is dead. Every command therefore answers `DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE` (type 5) immediately and fills in the real answer from a Sidekiq job via `PATCH /webhooks/{application_id}/{token}/messages/@original`. No command ever does its work inline — not even a fast one, because "fast" here means a cold Postgres connection plus an S3 image URL under load.
- The endpoint is public and unauthenticated. The Ed25519 signature check is the entire security boundary; see below.

### Where it lives

`POST /discord/interactions`, a top-level route in `config/routes.rb` next to `/emails/inbound` — **not** under `/api/v1`. The inbound-email webhook is the existing precedent for an unauthenticated third-party endpoint here, and it is one line; a `draw` file for one route would be more ceremony than routing.

Everything in `app/controllers/api/v1/` is public API surface: it carries hand-written OpenAPI components (`app/api_components/`), its integration tests generate the schema, and `bin/generate-schema` publishes it. A Discord-only RPC endpoint with a request body defined by Discord belongs in none of that. Keeping it outside also keeps it out of the generated TS client, which no frontend will ever call.

### Signature verification

Discord signs every request with Ed25519: `X-Signature-Ed25519` over `X-Signature-Timestamp + raw_body`, verifiable with the application's public key (visible in the app info as `verify_key`).

Ruby's OpenSSL does this without a new dependency:

```ruby
OpenSSL::PKey.new_raw_public_key("ED25519", [public_key_hex].pack("H*"))
  .verify(nil, [signature_hex].pack("H*"), "#{timestamp}#{raw_body}")
```

`ed25519 (1.4.0)` *is* in `Gemfile.lock`, but only as a transitive dependency of the SSH stack that Kamal uses. Building an auth boundary on a gem the Gemfile never asked for means a future `bundle update` can remove it. OpenSSL 3.6 is already a hard requirement of the app.

Rules for the controller:

- Verify against the **raw** body (`request.raw_post`) before parsing. Rails' parsed params are a different byte sequence and will never verify.
- `skip_before_action :verify_authenticity_token` — there is no session and no cookie; CSRF is meaningless and would reject every request.
- Reject with **401** on a bad or missing signature. Discord probes the endpoint with a deliberately invalid signature when you save the URL and refuses to accept it unless that probe gets a 401.
- Reject a timestamp older than 5 minutes, so a captured request cannot be replayed forever.
- The public key comes from credentials (`discord.public_key`), like `client_id` and `bot_token` in `config/app/main.yml`.

### The command table

Registration is `PUT /applications/{id}/commands` — a full replacement of the global command list, which makes it idempotent and safe to re-run. It is a rake task (`discord:commands:sync`), deliberately **not** a deploy hook: the endpoint is rate-limited per day, and command definitions change far less often than the app deploys.

## Phase 1 — endpoint, plumbing, `/ship`

The foundation plus one command, because a foundation with no command cannot be tested end to end.

| Change | File |
| --- | --- |
| Route | `config/routes.rb` |
| Controller: verify, PING, defer | `app/controllers/discord/interactions_controller.rb` |
| Signature check | `lib/discord/signature_verifier.rb` |
| Command registry | `lib/discord/commands/registry.rb` |
| Command base + `/ship` | `lib/discord/commands/base.rb`, `ship.rb` |
| Deferred follow-up | `app/jobs/discord/command_job.rb` |
| Follow-up transport | `lib/discord/interaction_client.rb` |
| Command registration | `lib/discord/api_client.rb`, `lib/tasks/discord.rake` |
| Locale mapping | `lib/discord/locale.rb` |
| Own Sidekiq queue | `config/sidekiq.yml` |
| Credentials | `config/app/main.yml`, `.env.tpl` |
| Flag | `config/feature_flags.yml` — `discord_commands` |
| Copy, seven locales | `config/locales/*/discord.yml` |

The follow-up gets its own client rather than a method on `ApiClient`: that path is authenticated by the interaction token in the URL, and `ApiClient` refuses to run without a bot token — a guard worth keeping rather than relaxing.

Discord sends the invoking member's own client locale (`locale`, with `guild_locale` as the fallback) on every interaction, so the answer is rendered under `I18n.with_locale` and the copy lives in all seven `discord.yml` files. `Discord::Locale` maps Discord's tags onto the app's, matching exactly first so `zh-CN` and `zh-TW` stay distinct.

Command jobs get their own Sidekiq queue, listed **first** in `config/sidekiq.yml`: it is the only queue with a user waiting on a spinner, and a loader burst on `notifications` would otherwise read as a bot that takes half a minute to answer.

`/ship <name>` reads the existing `Model` catalogue and answers with an embed: store image, manufacturer, classification, price, dimensions, a link to the model page. Name resolution reuses whatever the models filter already does for text search rather than inventing a second matcher; an ambiguous name answers with up to five candidates instead of guessing.

## Phase 2 — the rest of the read-only commands

Each is the same shape as `/ship`, so they are one PR per command at most and cheap:

| Command | Source | Note |
| --- | --- | --- |
| `/loaner <ship>` | loaner mappings | |
| `/hangar <user>` | public hangars | must honour the public-hangar setting; a private hangar answers "not public", never a 404 that leaks existence |
| `/compare <a> <b>` | compare data | embed, not the table |
| `/fleet` | fleet stats | resolves the guild via `FleetNotificationSetting.discord_guild_id` |

`/fleet` needs an **index on `fleet_notification_settings.discord_guild_id`** — the column exists but is unindexed, and this is the first read that looks a fleet up by it on a request path.

Every response is ephemeral by default (flag 64) unless the invoking member asked for a public post, so a busy channel does not fill with bot output.

## Phase 3 — RSVPs, without a Gateway

The handler exists; only the transport is missing, and HTTP interactions cannot carry it.

Instead, **poll**: `GET /guilds/{guild_id}/scheduled-events/{event_id}/users` returns the users subscribed to a scheduled event. `ScheduledEventSync` already runs per event and already knows `discord_guild_id` and `discord_event_id`, so it can diff the subscriber list against the FY signups and drive `ScheduledEventRsvpHandler#add!` / `#remove!` for the difference.

This is strictly better than a Gateway here: it survives restarts and missed events (a Gateway drops what happens while it is down), it needs no new process and no intents, and the handler's existing "never downgrade a Fleetyards commitment" logic makes repeated polling naturally idempotent.

The cost is latency — an RSVP lands on the next poll, not instantly. For an event days away that is invisible; the poll interval can tighten as the event approaches, reusing the same schedule the sync already follows.

## Phase 4 — event reminders with what Discord does not know

Discord's own event reminder knows the time and nothing else. Fleetyards knows the slots. A reminder post — "starts in 1 h · 6 of 14 slots open · sign up" with a deep link — carries information Discord cannot produce.

Goes through the existing webhook path (`lib/discord/webhook.rb`), so it needs **no bot permission at all** and works even in servers that never installed the bot. Reuses the `fleet_event.starting_soon` notification event that `FleetNotificationSetting::DEFAULT_IN_APP_EVENTS` already defines.

## Phase 5 — wishlist alerts as DMs

`lib/discord/ship_on_sale.rb` posts every sale to a channel. The same data filtered per user against their wishlist and delivered as a DM is the first thing that makes the Discord account link valuable to a *member* rather than to an org.

Mechanics: `POST /users/@me/channels` with the recipient, then a normal message. Requirements and limits, all of which need respecting rather than working around:

- The user must share a server with the bot, and must not have DMs closed. A failed DM is a normal outcome, not an error to retry into a rate limit.
- Opt-in per user, off by default, alongside the existing notification preferences. An unsolicited DM from a bot is the fastest way to get an app reported.

## Phase 6 — fleet roles ↔ Discord roles

What org admins actually ask for. Two tiers: a "verified member" role on account link, then a mapping from `FleetRole` ranks to Discord roles.

**This changes the install permissions.** Manage Roles is `1 << 28`, so `Discord::ApiClient::INSTALL_PERMISSIONS` and the app's Default Install Settings both move to `8_590_984_192 + 268_435_456 = 8_859_419_648`. Servers that installed under the old mask **keep the old grant** — Discord does not upgrade an existing install — so role sync must detect a missing permission and surface "re-authorise the bot" in the fleet settings UI instead of failing silently in a job.

Also note the role hierarchy: a bot can only assign roles **below its own highest role**. That is a server-configuration problem the app cannot fix, only detect and report.

Hangar-based roles ("owns a Carrack" → role) are the natural extension and deliberately last: they turn a per-link action into a continuous reconcile against every member's hangar, which is a different cost class from everything above.

## Order and why

1. **Phase 1** — nothing else exists without the endpoint.
2. **Phase 3** — finishes code already in the tree; highest value per line.
3. **Phase 2** — cheap, visible, no new mechanics.
4. **Phase 4** — no permissions, no new surface.
5. **Phase 5** — first outbound-to-person channel; wants the account link to be common first.
6. **Phase 6** — the only phase that forces a re-authorisation, so it goes last, once the bot is worth re-authorising for.

## Testing

The interactions endpoint gets an integration test in `test/integration/` — but **not** the `openapi-ruby` DSL, since it is not public API surface and must not enter the schema. Cases that matter: a valid signature dispatches, an invalid one is 401, a missing one is 401, a stale timestamp is 401, PING answers PONG, an unknown command name does not 500.

Signature verification gets a unit test with a fixed keypair, so a real signature is verified rather than a stub of the verifier.

Command handlers are unit-tested on their embed output, with no HTTP involved — the same reason `ScheduledEventRsvpHandler` is pure ActiveRecord and testable today.
