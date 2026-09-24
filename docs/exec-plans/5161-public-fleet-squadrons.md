# Public fleet page: squadrons for visitors

## Goal

Somebody outside a public fleet, signed out or not a member, sees its squadrons on the fleet's front page: names and sizes, nothing more. Members keep the strip they have.

## Context

`public/fleets/:slug/squadrons` (index and show) already serves a narrow `PublicFleetSquadron`: name, slug, colour, icon and a `memberCount` that is null unless the fleet shares its stats. No frontend code called it. The strip on `pages/fleets/[slug]/index.vue` read the member endpoint only, gated on `membership.capabilities.readSquadrons`, so a visitor never saw it.

A second gap sat under the first: the strip is also gated on the fleet having `fleet_squadrons` switched on, read off the fleet payload's `features`. The public fleet payload never carried `features`, although the `Fleet` schema it answers with declares it required, so the flag read false for every visitor.

Resolves #5161

## Decisions

### D1 — Add `features` to the public fleet payload

The frontend gates every fleet section on `isFleetFeatureEnabled(fleet, …)`. Rendering `fleet.features` outside the cache, as the member partial does, makes that work for a visitor without a second rule for them. It brings the payload in line with the schema it already claims; no schema change.

Rejected: firing the public squadrons request regardless and treating the 404 as "off". That is a failed request on every public fleet page whose fleet has no squadrons.

### D2 — Member means an accepted membership

`useFleetMembership` also answers for an invited or requested membership. `Public::FleetPolicy#member?` counts only `accepted`, so the page does the same: an accepted member goes by `readSquadrons`, everybody else gets the public list. A member whose role cannot read squadrons sees neither — the fleet chose that for the role.

### D3 — One unlinked row

`PublicFleetSquadron` has no `team` flag, so squadrons and teams share one row, and a squadron's own page needs a login, so the chips are not links. The hover state now applies to links only. The size uses the existing `labels.fleet.squadrons.memberCount` label and is left out where the API returns null.

## What changed

1. `app/views/api/v1/public/fleets/_fleet.jbuilder` — `features` outside the cache; covered in `public_fleets_show_test.rb`.
2. `pages/fleets/[slug]/index.vue` — `usePublicFleetSquadrons` for non-members, a public strip with sizes; the member strip additionally requires an accepted membership.
3. `SquadronEmblem` accepts a `PublicFleetSquadron`.
4. `pages/fleets/[slug]/index.spec.ts` — visitor, invited, member, member without the capability, flag off.

## Intent Verification

- [x] **Visitors see the list** — signed out, a public fleet with squadrons on shows them, without member identities or descriptions
- [x] **Sizes follow the stats switch** — a count shows only where `memberCount` is not null
- [x] **Members unchanged** — an accepted member with `readSquadrons` sees both strips from the member endpoint, and no public request is made
- [x] **Nothing when off** — no request and no strip when the fleet has squadrons switched off

## Key files

| File | Role |
|------|------|
| `app/views/api/v1/public/fleets/_fleet.jbuilder` | The public fleet payload, now with `features` |
| `app/frontend/frontend/pages/fleets/[slug]/index.vue` | The front page and both strips |
| `app/frontend/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue` | Takes the public squadron type |

## Progress
- [x] Public payload carries `features`
- [x] Front page renders the public list for non-members
