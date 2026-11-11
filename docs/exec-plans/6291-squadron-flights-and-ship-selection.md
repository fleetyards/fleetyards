# Squadrons: Flights to prefill event teams, slots, ships and people

Working plan for #6291. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Members choose which of their ships a squadron gets (officers can ask for specific ones), and a squadron's Flights — ships, slots and primary/alternate members — prefill event and template teams, inviting the members onto the event.

## Open questions

- None.

## What changed

### Phase 1 — Per-squadron ship selection
1. `fleet_squadron_memberships`: `ships_filter` (all / hangar_group / picked / none, default all) + `hangar_group_id`.
2. `fleet_squadron_membership_vehicles` (membership + vehicle, unique pair) for hand-picked ships.
3. A squadron vehicle scope that is the intersection of the member's `FleetVehicle` rows and the squadron selection; `FleetVehicleFiltersConcern#for_squadrons` narrows by vehicle instead of `user_id` (fleet vehicles, public fleet vehicles, fleet stats).
4. API: read/update own squadron membership ship settings; tests in `test/integration/api/v1/` feed the schema.
5. Frontend: per-squadron ship settings, modelled on `pages/fleets/[slug]/settings/membership.vue`.

### Phase 2 — Officer ship requests
1. `FleetSquadronVehicleRequest` (squadron membership + vehicle + requested_by), validations like `FleetSquadronRequest`.
2. Accept adds the vehicle to the member's picked set (switching `all`/`hangar_group` to keep the ship included); decline destroys.
3. Notification types: request received (member), accepted (requester). Labels in every locale, `useNotificationActions.ts`.
4. Endpoints + policy (`manages_members?` or `MEMBERS_MANAGE_PRIVILEGES` to create; the member to accept/decline).
5. Frontend: request button on a member's ship in the squadron; incoming requests list for the member.

### Phase 3 — One team-tree copier
1. Extract the team/slot/ship/allowed-model copy from `FleetEvent.from_mission!` into one copier that takes a source team (MissionTeam or Flight) and a target (FleetEventTeam or MissionTeam).
2. `from_mission!` uses it; behaviour unchanged (existing tests stay green).

### Phase 4 — Flights
1. Tables: `fleet_squadron_flights` (squadron, name, description, rank/position), `flight_ships` (+ `flight_ship_models`), `flight_slots` (polymorphic flight/ship), `flight_slot_members` (slot, squadron membership, position, optional vehicle from the member's squadron selection).
2. CRUD API mirroring mission teams/ships/slots; policy: `manages_members?` ranks + `fleet:squadrons:manage` edit, squadron readers read.
3. Frontend: Flights tab on the squadron (`squadronDetailRoutes`), editor reusing the `Missions/{TeamCard,ShipCard,ShipModal,SlotList}` pieces.

### Phase 5 — Apply a Flight
1. `source_flight_id` on `fleet_event_teams` and `mission_teams`; Flight picker after `SquadronSourceSelect` in `EventTeamModal` and `Missions/TeamModal`.
2. Template teams keep the ordered member list on their slots (`mission_slot_members`); `from_mission!` turns it into invites.
3. Event teams: the first member still in the squadron and fleet gets an `invited` signup on the slot.

### Phase 6 — Invites and alternates
1. New signup status (see open questions) in `FleetEventSignup` constants and the enum schema.
2. Member accepts (→ confirmed, or pending under `confirmation_required`) or declines.
3. Decline / withdraw / leaving the fleet (`FleetMembership#withdraw_upcoming_event_signups`) moves the next alternate up with a new invite.
4. Notifications: invited (in-app + mail via `FleetEventMailer`, Discord subscriber if it applies).

## Intent Verification

- [ ] **Squadron ship choice** — a member set to "hand-picked" with two ships shows exactly those two on the squadron's ships page and stats; fleet ships page unchanged.
- [ ] **Narrowing only** — a ship hidden from the fleet never appears for the squadron, whatever the selection.
- [ ] **Officer request** — an officer requests a member's ship; the member gets a notification, accepts, and the ship appears for the squadron.
- [ ] **Flight copy** — picking a Flight on an event team copies its ships, slots and allowed models; editing the Flight afterwards leaves the event unchanged.
- [ ] **Template → event** — a template team built from a Flight creates invites for the primaries when an event is created from it.
- [ ] **Alternates** — the primary declining hands the slot to the next alternate as a new invite; members who left are skipped.
- [ ] **Permissions** — a plain squadron member cannot edit Flights or request ships.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_squadron.rb`, `fleet_squadron_membership.rb` | Squadron, member, selection |
| `app/models/fleet_membership.rb` | `ships_filter`, `FleetVehicle` rows, signup withdrawal on leave |
| `app/controllers/concerns/fleet_vehicle_filters_concern.rb` | `for_squadrons` narrowing |
| `app/controllers/api/v1/fleet_vehicles_controller.rb`, `public/fleet_vehicles_controller.rb`, `fleet_stats_controller.rb` | Callers of the squadron narrowing |
| `app/models/fleet_squadron_request.rb` | Request/accept/notify pattern to mirror |
| `app/models/notification.rb` | Notification type registry |
| `app/models/fleet_event.rb` (`from_mission!`) | Copy to extract |
| `app/models/concerns/built_from_squadron.rb` | Team ↔ squadron link |
| `app/models/fleet_event_signup.rb`, `app/controllers/api/v1/fleet_event_signups_controller.rb` | Signup statuses and flow |
| `app/lib/notifications/in_app/fleet_event_subscriber.rb`, `app/mailers/fleet_event_mailer.rb` | Signup notifications |
| `app/frontend/frontend/pages/fleets/[slug]/squadrons/` | Squadron pages, tabs |
| `app/frontend/frontend/components/Fleets/Missions/`, `.../Events/EventTeamModal`, `.../Squadrons/SquadronSourceSelect` | Editors and team modals |

## Not in scope (deferred)

- None yet.

## Discovery Log

- **2026-11-11** Initial research and plan creation. Fleet visibility is materialised as `FleetVehicle` rows; squadron narrowing is by owner only. No endpoint lets an admin create a signup for someone else, so invites need a new creation path.

## Progress

- [ ] Phase 1 — Per-squadron ship selection
- [ ] Phase 2 — Officer ship requests
- [ ] Phase 3 — One team-tree copier
- [ ] Phase 4 — Flights
- [ ] Phase 5 — Apply a Flight
- [ ] Phase 6 — Invites and alternates
