# Accept/decline buttons on the Discord join-request message

Working plan for #5175. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A join request is posted to the fleet's officers channel with Accept and Decline buttons, and a click settles it after re-checking the clicking officer.

## What changed

### Phase 1 — Post the join request
1. `ChannelPost#deliver` and `AnnouncementTarget#deliver` take optional `components:`.
2. `Discord::JoinRequestMessage` builds the pending payload (content + two buttons, `custom_id` `fleet_request:<accept|decline>:<membership id>`) and the settled payload (outcome line, buttons disabled).
3. `FleetMembership` `request` event also enqueues `Discord::PostJoinRequestJob`, which posts through `AnnouncementTarget.officers` if the membership is still `requested`.

### Phase 2 — Handle the click
1. `InteractionsController` handles type 3 (`MESSAGE_COMPONENT`): ack with `DEFERRED_UPDATE_MESSAGE` (6), enqueue `Discord::ComponentJob`.
2. `Discord::Components::FleetRequest` re-checks guild binding, account link and policy on every click, then looks the membership up *within the guild's fleet*.
   - settled now or earlier → edit the original message (outcome, disabled buttons)
   - refusal → ephemeral follow-up to the clicker, message untouched
3. `InteractionClient#create_followup`, and `InteractionClient.expired?` shared with `CommandJob`.
4. Decision logic shared with the slash commands via `Discord::JoinRequestDecision`.

### Phase 3 — Settings copy
1. `officersChannelHint` mentions join requests, all 7 locales.

## Intent Verification

- [x] **Join-request message carries Accept and Decline buttons**
- [x] **A click is a type-3 interaction whose custom_id identifies the request; link and privilege re-checked on every click**
- [x] **The message updates to show the outcome and disables the buttons**

## Key files

| File | Role |
|------|------|
| `app/controllers/discord/interactions_controller.rb` | Interactions endpoint |
| `lib/discord/commands/fleet_request_decision.rb` | Slash-command decision logic |
| `lib/discord/announcement_target.rb`, `lib/discord/channel_post.rb` | Officers channel posting |
| `app/models/fleet_membership.rb` | `request` AASM event |

## Not in scope (deferred)
- **Updating the message when the request is settled elsewhere** (website, slash command) — needs the message id stored on the membership. Until then a click on a stale message shows the current state and disables the buttons.

## Discovery Log

- **2026-09-25** No join-request message existed on Discord at all (`fleet_member_requested` is app + mail only); the officers channel from #5192 is the bot-posted, officers-only target. Buttons need a bot-sent message, so webhook-only fleets get none.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
