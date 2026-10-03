# Show friends and fleet members on location pages

Working plan for #5384. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A signed-in reader sees, on a location page, which friends and fleet mates have their current location at that place or inside it.

## What changed

### Phase 1 — API
1. `Locations::People`: the place's subtree by `parent_id` (recursive CTE), the reader's accepted friends (when `friends` is on) and the accepted, kept members of fleets whose roster the reader may read, whose `current_location_id` is in the subtree. One entry per person: friend flag, shared fleets.
2. `GET /api/v1/locations/:slug/people`, signed in or a token (fleet mates only with a `fleet`/`fleet:read` token).
3. `V1::Schemas::LocationPeople` / `LocationPerson`, integration test, `bin/generate-schema`.

### Phase 2 — Page
1. `Locations/People` component in the rail (and above the missions on a system page), fetched only when signed in.
2. Labels in all seven locales.

## Intent Verification

- [ ] **Subtree** — someone at a Lorville clinic shows on Lorville, Hurston and Stanton.
- [ ] **No new exposure** — a pending friend, a member of another fleet, a fleet whose roster the reader cannot read, the reader themself: none listed. Anonymous: 401.

## Key files

| File | Role |
|------|------|
| `app/services/locations/people.rb` | Who is there |
| `app/controllers/api/v1/locations_controller.rb` | `people` action |
| `app/frontend/frontend/components/Locations/People/index.vue` | The list |
| `app/frontend/frontend/pages/locations/[slug].vue` | Where it sits |

## Discovery Log

- **2026-10-03** Users already carry a linked `current_location` (#5371); friendships and rosters show it.

## Progress
- [x] Phase 1
- [x] Phase 2
