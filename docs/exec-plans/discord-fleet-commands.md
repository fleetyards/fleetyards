# Discord Fleet & Member Commands

Continues `discord-bot.md`, whose six phases have all shipped: the interactions endpoint, five read-only commands, RSVP polling, event reminders, wishlist DMs and fleet↔Discord role sync.

What exists is entirely a **catalogue** bot. Four of the five commands look ships up; `/fleet` shows counts. Nothing a fleet officer does day to day is reachable from Discord, and nothing the bot answers is ever private to the person who asked — `EPHEMERAL_BY_DEFAULT = false` and no definition overrides it.

This plan adds fleet management and private answers, in five phases that each ship on their own.

## Foundation

Three mechanics the current plumbing either cannot express or has never exercised. All of Phase 1–5 rests on them, so they are decided here once.

### Subcommands do not work today

`/fleet invite` is not a new command, it is a subcommand of an existing one, and three places assume a flat namespace:

- `InteractionsController#command_options` flattens exactly one level (`Array(options).to_h { |o| [o["name"], o["value"]] }`). Discord sends a subcommand as an option of type 1 carrying **no `value`** and a nested `options` array, so `/fleet invite limit:5` arrives as `{"invite" => nil}` and the limit is gone.
- `Registry.handler_for` and `Registry.ephemeral?` key on the top-level name only, so the invite would dispatch to `Discord::Commands::Fleet`.
- `Registry.payload` strips `:handler` and `:ephemeral` at the top level only. A nested definition carrying those keys is rejected by Discord's `PUT /applications/{id}/commands` as unknown fields — and because that endpoint is a full replacement, a rejected payload leaves the *previous* command list live, which reads as "the sync did nothing".

The alternative is flat commands (`/fleet-invite`, `/fleet-events`). It needs no plumbing change, and it is the wrong choice: it puts one fleet's internals in the global command picker of every server the bot is in, and Discord's own convention for a noun with verbs is subcommands.

So: the registry gains nested definitions, `handler_for(name, subcommand)` and `ephemeral?(name, subcommand)`; the controller extracts the subcommand and recurses into its options; `payload` strips our keys at every depth. New option types alongside `STRING = 3`: `SUB_COMMAND = 1`, `INTEGER = 4`, `BOOLEAN = 5`, `USER = 6`.

Visibility is the reason this cannot be skipped: the fleet overview must stay public and `/fleet invite` must not be, and `ephemeral?` has to be able to tell them apart *before* the job runs.

**The price, which is not optional: `/fleet` stops being callable.** Discord will not invoke a command that has subcommands — its options are either parameters or subcommands, never both — so the shipped fleet overview moves to `/fleet info`. There is no arrangement in which `/fleet` keeps answering *and* `/fleet invite` exists under the same name. Nothing resolves a bare `/fleet` to the parent either: the endpoint is public, so a hand-rolled bare call must refuse rather than dispatch to the overview.

### Ephemeral is already supported, and has never been used

`InteractionsController#acknowledge_command` consults `Registry.ephemeral?` and sets flag 64 on the deferred acknowledgement, and `Registry.ephemeral?` already reads a per-definition `ephemeral:` key. A definition that carries `ephemeral: true` therefore works today; nothing sets it.

The consequence to design around, not to fight: **a command is wholly public or wholly private.** Discord fixes visibility at the acknowledgement and ignores flags on the follow-up, so `/fleet invite` cannot post a public "invite created" plus a private link, and `/fleet members` cannot answer a hit in the channel and a refusal privately.

### Authorization: Discord roles are never authority

Every command below resolves the caller the way `Discord::Commands::Fleet#member?` already does — `OmniauthConnection.find_by(provider: "discord", uid: discord_user_id)` — and then asks the fleet's own privilege system, `FleetMembership#has_access?` / `#capabilities`.

A guild administrator with no Fleetyards membership gets nothing. Manage Roles in Discord does not create a `fleet:invites:create`. This is the same rule `/fleet` already applies to *reading* a fleet (sharing a server is not membership); writes only make it matter more.

That produces three distinct refusals, each needing its own copy, all ephemeral:

| Situation | Answer |
| --- | --- |
| No linked Discord account | "link your account", with the settings link |
| Linked, not a member of this guild's fleet | the fleet's name is *not* revealed beyond what `/fleet` already does |
| Member without the privilege | names the missing capability in plain words, not the privilege string |

Writes ride a **new flag**, `discord_fleet_commands`, declared in `config/feature_flags.yml`. `discord_commands` gates dispatch as a whole and is on in production; the first path that mutates a fleet from Discord wants a switch of its own. Registry definitions stay published either way — a flagged-off command answers the existing "disabled" message rather than vanishing from the picker, which is the difference between "not yet" and "broken".

## Phase 1 — `/fleet invite`

The smallest useful write, and the one org admins ask for.

| Option | Type | Note |
| --- | --- | --- |
| `limit` | INTEGER, optional | uses on the link; `FleetInviteUrl` validates `>= 0`, nil means unlimited |
| `expires_in` | STRING choices, optional | `1h` / `24h` / `7d` / `never`, mapped to `expires_after` |

Creates a `FleetInviteUrl` owned by the **resolved caller** (`user_id`), authorized against the `create_invites` capability, and answers with `invite_url.url`.

- **Ephemeral, non-negotiably.** The token *is* the credential; a public answer hands the fleet to the channel, guests included.
- **The URL comes from the model.** `FleetInviteUrl#url` picks `short_fleet_invite_url` when `short_domain` is configured and `frontend_fleet_invite_url` otherwise. A command that builds its own path via `Base#url_for_path` produces a link that works but is not the one the website hands out.
- **The copy must not overstate what the link does.** `FleetInviteUrlsController#use` creates the membership and then calls `request!` — the invitee lands in `requested` and still needs accepting. So the answer says the link *asks to join*, and mentions where those requests appear. Phase 4 is what closes that loop from Discord.
- `FleetInviteUrl` has no `paper_trail`, so nothing records that a link was minted from Discord beyond the row's `user_id`. Worth noting as a gap; not worth adding a versioned model here.

**Deliberately not in this phase:** `/fleet invite @user`, which would create a `FleetMembership` and fire `invite!` for a mentioned Discord user. It needs a second capability (`create_members`), and a mentioned user who never linked an account cannot be invited at all — so the command would sometimes silently degrade to producing a link, which is two outcomes wearing one name. Its own step, after the roster commands make membership state visible.

## Phase 2 — `/fleet events`

Reads the guild's fleet through the existing `FleetNotificationSetting.discord_guild_id` binding and lists up to five upcoming events: title, start, availability, link.

- **Ephemeral, which is not obvious.** `fleet:events:read` is a *member* default privilege, so events are internal data — and the guild may have guests, the same reason `/fleet` refuses non-members. A channel post would leak the schedule to exactly the people the privilege excludes.
- Scope: `fleet_events.active_status.upcoming`, excluding `draft` — a draft is a work in progress, and listing it in Discord publishes it in every sense that matters.
- **Availability must not be defined a second time.** `Discord::EventReminder` already computes "6 of 14 slots open", falls back to a signup count when an event has no slots (because "0 of 0 slots open" reads as full), excludes withdrawn signups, and narrows to an occurrence date. Those private methods (`availability`, `taken_slots`, `signups_scope`) move to a shared object both use. A bot that disagrees with its own reminder about how many slots are open is a bug nobody can reproduce.
- Recurring series: occurrences live on `fleet_event_occurrence_states` and carry their own overridden titles and dates. The list is of *occurrences*, not of series rows, or a weekly op appears once and at the wrong date.

## Phase 3 — `/fleet members`

| Option | Type | Note |
| --- | --- | --- |
| `filter` | STRING choices, optional | `all` (default) / `pending` |

Gated on `read_members`, always ephemeral: a roster is usernames and RSI handles, which is personal data whatever the fleet's public flag says.

- `all` lists accepted members; `pending` lists `requested` — the queue Phase 4 acts on.
- Both scopes go through `kept` (memberships are `Discard::Model`) and match the state literal the existing `/fleet` count already uses (`aasm_state: "accepted"`).
- Capped at ten with a "+N more" line and a link to the fleet's member page, the shape `/hangar` already uses; ordering follows `FleetMembership::DEFAULT_SORTING_PARAMS`.

## Phase 4 — acting on a join request from Discord

Two steps, deliberately separate reviews.

**Step 1 — `/fleet accept <username>` / `/fleet decline <username>`.** Same plumbing as everything above: a subcommand, a capability check (`update_members`), and the existing `accept_request` / `decline` AASM events. Ephemeral. `whiny_transitions: false` means a second caller gets `false` rather than an exception, so a repeated accept answers "already accepted" instead of an error.

**Step 2 — buttons on the request notification.** This is the first interaction that is not a command, and the controller cannot receive it yet:

- `MESSAGE_COMPONENT` is interaction type **3**. `InteractionsController#create` handles 1 and 2 and drops everything else to `head :no_content`, which Discord renders as "This interaction failed".
- Components acknowledge with `DEFERRED_UPDATE_MESSAGE` (**6**) when the original message is being edited. Type 5 posts a *new* message and leaves the button spinning.
- `custom_id` (max 100 chars, e.g. `fleet_membership:accept:<uuid>`) comes back from the client and is therefore **a parameter, not authority**. The caller is re-resolved and the capability re-checked on every click. "Only an officer can see this button" is not a security property — the id can be replayed by anyone who can craft an interaction, including for a membership in a different fleet.
- **Where the message comes from matters.** The per-fleet path built in the previous plan posts through the encrypted `discord_webhook_url`; interactive components require a message sent by the application itself, so the button post needs `discord_channel_id` and a bot token — i.e. it only works for fleets that installed the bot, not for the webhook-only fleets Phase 4 of the old plan deliberately supported. Confirm against Discord's current component rules before building, and fall back to Step 1 for webhook-only fleets.

`notify_fleet_admins` already fires on `request!`, so this hangs off an existing hook rather than a new one.

## Phase 5 — private answers about yourself: `/myhangar`, `/wishlist`

Both are flat commands, both `ephemeral: true`, and both need **only** the account link: no guild binding, no fleet, no privilege. `InteractionsController#invoking_user_id` already falls back to `payload["user"]["id"]`, which is the DM shape, so these work in a DM with the bot as well as in a channel. If that is not wanted, the definitions need an explicit `contexts` — global commands are DM-enabled by default.

- **`/myhangar` is not `/hangar` with the username filled in.** `Discord::Commands::Hangar` exists to show a *stranger's* hangar: it requires `public_hangar?` and scopes `vehicles.purchased.public`. For the owner both layers fall away, and the command should show what the owner sees on their own hangar page — ships in private hangar groups included. Reusing the existing scope would silently omit exactly the ships the asker is most likely to be checking on.
- **`/wishlist` is `user.vehicles.wanted`**, grouped and capped the same way. `users.public_wishlist` and `User#public_wishlist_url` already exist, so a `/wishlist <username>` variant is a later, cheap addition — and it must copy `/hangar`'s rule that a private wishlist and an unknown username get the *same* answer, or the command becomes a probe for which accounts exist.
- The "no linked account" refusal is the most frequently hit answer in this entire plan and the only one that is also a conversion path. It gets real copy and the settings deep link, in all seven locales.
- It pairs with the wishlist sale DMs already shipped: `/wishlist` is where a member checks what those alerts cover.

## Order and why

1. **Phase 5** — two read-only commands and one new key in the registry. It proves the ephemeral acknowledgement in production with nothing at stake, and it is the only phase that needs no subcommand plumbing.
2. **Phase 1** — the subcommand foundation plus the first write, behind its own flag.
3. **Phase 3** — cheap once subcommands exist, and it makes membership state visible before anything acts on it.
4. **Phase 2** — no new mechanics; its only real work is extracting the shared availability logic.
5. **Phase 4** — Step 1 with the rest, Step 2 last: it is the only piece that adds a new interaction type and the only one whose delivery constraint (`discord_channel_id`, not the webhook) can cut fleets out.

## Testing

- **Registry**: every definition survives `payload` with no `:handler` or `:ephemeral` at any depth, including nested subcommands; a table-driven assertion that each command intended to be private answers `Registry.ephemeral?` truthfully — visibility is decided at the acknowledgement, so no unit test over a command's payload can catch that regression.
- **Controller**: a subcommand dispatches to the right handler with its nested options intact; interaction type 3 does not fall through to `no_content`; a `custom_id` naming a membership in another fleet is refused.
- **Commands**: unit tests over the returned payload, no HTTP, as the existing five already are — plus one refusal test per authorization step (unlinked, non-member, under-privileged), since those three are the answers most callers will actually see.
- **Locales**: the keys land in all seven `config/locales/*/discord.yml` in the same commit. Nothing in CI checks locale parity and `enableFallback` hides a missing key behind English, so a gap ships silently.
- No OpenAPI surface: like the endpoint itself, none of this is public API and none of it enters the generated schema.
