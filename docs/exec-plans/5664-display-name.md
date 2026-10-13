# Display name for the public hangar, plaque and fleet roster

Working plan for #5664. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A user's optional display name replaces their username on the public hangar, the plaque's captain line and the fleet roster, and a plaque can override the captain name.

## Open questions

- None.

## What changed

### Phase 1 — Backend

1. Migrations: `users.display_name`, `vehicles.plaque_captain` (both nullable strings).
2. `User`: normalise blank to nil and strip, cap at 50, version it with paper_trail; `name_shown` fallback for server-side titles.
3. `Vehicle`: normalise and cap `plaque_captain`; permit it with the plaque fields.
4. Payloads and components: own user, public user, admin user (+ input), vehicle plaque partial, public vehicle owner block (`user_display_name`, behind `hide_owner`), fleet member.
5. Server-rendered titles of the public hangar, wishlist, vehicle and plaque pages use the display name.
6. Integration and model tests; regenerate the schema.

### Phase 2 — Frontend

1. Profile settings: display name field.
2. Public hangar: heading, titles, share titles and breadcrumbs use the display name.
3. Plaque: one captain resolution (override, display name, username) for the edit modal previews, the capture, the overview card and the public plaque modal; the form gets a captain field.
4. Fleet roster: `MemberName` falls back nickname → display name → username.
5. Admin user edit: display name.
6. Labels in all seven locales; specs.

## Intent Verification

- [ ] A display name set in the profile shows on the public hangar heading, its page title and its link preview title.
- [ ] A plaque shows the override, else the display name, else the username; the saved preview picture matches.
- [ ] The fleet members list shows the display name when no nickname is set.
- [ ] `hide_owner` keeps both names out of public vehicle payloads.

## Key files

| File | Role |
|------|------|
| `app/models/user.rb`, `app/models/vehicle.rb` | Columns, normalisation, limits |
| `app/controllers/api/v1/users_controller.rb`, `vehicles_controller.rb` | Permitted params |
| `app/controllers/frontend/hangar_controller.rb` | Server-rendered titles |
| `app/frontend/frontend/components/Vehicles/Plaque*` | Captain line and form |
| `app/frontend/frontend/components/Fleets/MemberName` | Roster names |
| `app/frontend/frontend/composables/usePublicHangarMeta.ts`, `components/Hangar/PublicHeading` | Public hangar names |

## Not in scope (deferred)

- None.

## Discovery Log

- **2026-10-13** Initial research and plan creation.
- **2026-10-13** The editor's live previews named the owner even when hidden; they now share the captured picture's resolution. Possessive titles keep a display name as written and capitalise only a username.

## Progress

- [x] Phase 1
- [x] Phase 2
