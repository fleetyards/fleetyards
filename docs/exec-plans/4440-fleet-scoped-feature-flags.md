# Make fleet_logistics a fleet-scoped feature flag with a fleet settings Features tab

## Goal

A fleet admin can switch fleet-wide features on for their own fleet from a Features tab in the fleet settings, each flag resolves per fleet rather than across every fleet the user belongs to, and individual members can no longer self-activate a fleet-wide feature from their personal settings.

## Context

`fleet_logistics` is already evaluated against the fleet as a Flipper actor: every logistics controller calls `feature_enabled?("fleet_logistics", @fleet)`, and `Api::BaseController#feature_enabled?` expands that to `Flipper.enabled?(flag, current_resource_owner, @fleet)` — user OR fleet. What is missing is the ownership model around that gate.

Three problems follow from it:

1. **`GET /features` leaks flags across fleets.** `Api::V1::FeaturesController#show` unions the user's flags with flags enabled for *any* fleet they belong to. One fleet with `fleet_logistics` on makes `isFeatureEnabled(FLEET_LOGISTICS)` true on every fleet page, so `logistics.vue` renders the tab for fleets that do not have it and the API then 403s. It also loops `Flipper.features × fleets` per request.
2. **A plain member can switch on a fleet-wide feature.** `fleet_logistics` is `self_service: true`, so it appears in every user's Settings → Features and `UserFeaturesController#enable` calls `enable_actor(current_resource_owner)`. Because the backend ORs the user actor in, any member unlocks fleet logistics across all their fleets without holding `fleet:manage`.
3. **There is no fleet-scoped self-service surface.** Only `/admin/features` can `enable_actor(flag, fleet)`.

Resolves #4440

## Decisions

### D1 — The registry declares *who owns* the toggle, not just that one exists

`self_service: true` conflates "a toggle exists" with "the user owns it". Replace the boolean with a scope so the registry answers both questions:

```yaml
fleet_logistics:
  description: "Fleet logistics — fleet inventories with a deposit/withdrawal ledger"
  self_service: fleet
```

`self_service` accepts `user` or `fleet`; `true` stays accepted as an alias for `user` so the other entries need no churn and old registries keep validating. `Definition` exposes `self_service?` (unchanged meaning: a toggle exists) plus `self_service_scope`, and `Registry::KNOWN_KEYS` gains no new key.

Rejected: a separate `scope:` key. It would be legal to write `scope: fleet` without `self_service`, which means nothing, and the validator would have to reject that combination — a constraint the single key makes unrepresentable.

### D2 — `FeatureSetting` carries the scope, so the admin UI keeps ownership

`FeatureSetting.self_service` is what the admin toggles at `/admin/features`, and the synchronizer deliberately seeds it once and never overwrites it. Scope has to live next to it or the two disagree after an admin toggle. Add a `self_service_scope` string column (default `"user"`, not null) and seed it alongside `self_service`.

The synchronizer keeps its never-overwrite rule for `self_service`, but **does** reconcile `self_service_scope` on every sync: scope is a property of the code that reads the flag, not a rollout decision an admin makes, so a flag that becomes fleet-scoped in a release must not stay user-toggleable because a row already existed.

### D3 — Fleet flags come from the fleet payload, not from `GET /features`

`GET /features` cannot answer "is this flag on for *this* fleet" without a fleet parameter, and adding one makes a per-page request out of something already fetched. Instead `_fleet.jbuilder` exposes `features` — the fleet-scoped flags enabled for that fleet — and `useFeatures` gains a fleet-aware companion.

`json.features` must sit **outside** the `json.cache!` block, next to `my_fleet`. Inside it the flag state would be cached under `["v1", fleet]` and an admin toggle would not show up until the fleet record itself changed.

`GET /features` then drops its fleet union entirely and returns only what is enabled for the user actor.

Rejected: `GET /fleets/:slug/features` as the read path for rendering. It is the write path's natural sibling and will exist for the settings tab, but making every fleet page wait on a second request to decide whether to render a tab is worse than a field on a payload that is already loaded.

### D4 — The backend keeps the user actor in the OR

`Flipper.enabled?(flag, current_resource_owner, @fleet)` stays as it is. It is how a single person is trialled onto a feature from `/admin/features`, and removing it would break that. What changes is that the user actor is no longer reachable through self-service for a fleet-scoped flag, so a member cannot put themselves in that gate.

### D5 — Removing the union forced every fleet-page flag read to become fleet-aware

`fleet_starmap` and `fleet_worldmap` are not self-service, but they *can* be enabled for a fleet actor from `/admin/features` — and the union was the only thing carrying that to the frontend. Deleting it would have silently switched those features off for any fleet gated that way.

So the fleet-aware read is not limited to `fleet_logistics`: `isFleetFeatureEnabled(fleet, flag)` mirrors the backend gate exactly (`Flipper.enabled?(flag, user, fleet)` — on for the viewer *or* for this fleet), and every fleet-page read goes through it. `FeatureGuard` takes an optional `fleet`, and the router guard consults the fleet named in the route.

The guard needs to know *when* a route's flag is fleet-scoped, because `:slug` also names models and ships — fetching the fleet endpoint with a model slug would throw, and the guard's fail-open `catch` would then wave every flagged model route through. A `featureScope: "fleet"` route meta makes that explicit at the route definition rather than inferring it from the path.

### D6 — A fleet flag has two switches, and personal settings keeps its own

The original framing of problem 2 above was wrong, and worth recording. Enabling a fleet flag on the **user** actor does not switch the feature on for the fleet: for another member B, `Flipper.enabled?(flag, B, fleet)` is still false. It is a preview for one person, not a fleet-wide change. So the personal toggle stays — it is how someone tries a beta before their fleet commits to it — and the fleet tab is the separate switch that turns it on for every member.

`enable`/`disable` therefore accept **any** self-service flag (`FeatureSetting.self_service_anywhere?`), always toggling the user's own actor. The scope decides where the *fleet-wide* switch lives, not whether a personal one exists.

That gives one flag two states, so `GET /user-features` reports both:

| field | meaning | drives |
| --- | --- | --- |
| `enabledForSelf` | the user's own gate | which way the switch flips |
| `enabled` | what the user actually has, own gate **or** a fleet's | the state pill |
| `fleets` | the user's fleets that switched it on | the "Enabled by fleet" marker and its links |
| `scope` | which surface owns the fleet-wide switch | whether to mark the row at all |

A fleet's grant cannot be overridden per user — the backend ORs both actors, so a personal `disable` could not take it away. Rather than return 200 for a change the user will not see, `enable`/`disable` **403** while any of their fleets has the flag on, and the page disables the switch for those rows. `fleets` names them, linked to the fleet page, so a member can see where the feature came from instead of only that they cannot turn it off.

Only fleet-scoped flags consult the fleets: nothing reads a user-scoped flag against a fleet actor, so a gate there would grant nothing and must not read as enabled. Accepted memberships only — a pending invitation is not membership.

The `scope` enum is safe to declare on the response where `FeatureFlagName` is not: the scopes are a closed set, so they will not grow a value on every new flag and trip `response-property-enum-value-added`.

### D7 — `fleet:manage` gates the tab, no new privilege

`app/models/fleet.rb:45` already treats `fleet:manage` as the admin privilege and the settings routes already use it (`fleet-settings-fleet`). A dedicated `fleet:features:manage` privilege would need a `FleetRole` migration and a permanent-role edit path for no gain — turning features on and off for the whole fleet is squarely an admin act.

## What changed

### Phase 1 — Registry scope

1. `lib/feature_flags/definition.rb` — `self_service` accepts `user`, `fleet`, `true` (alias for `user`) or `false`; exposes `self_service?`, `self_service_scope`, `self_service_user?`, `self_service_fleet?`.
2. `lib/feature_flags/registry.rb` — `self_service` left `BOOLEAN_KEYS` for a dedicated value check, `Registry#self_service(scope)` selects the definitions for one surface.
3. `config/feature_flags.yml` — `fleet_logistics` is `self_service: fleet`; `hangar_inventories` and `ship_inventories` spell out `user`; the header documents the scopes.
4. `test/lib/feature_flags/registry_test.rb` — every form plus an unknown scope.

### Phase 2 — Persist the scope

1. `db/migrate/20260818120000_add_self_service_scope_to_feature_settings.rb` — string, not null, default `"user"`.
2. `app/models/feature_setting.rb` — `self_service?(name, scope:)` and `self_service_feature_names(scope:)` take the scope as a **required** keyword so no caller can cross surfaces by omission; `self_service_anywhere?` serves the one genuinely scope-agnostic caller, the admin view.
3. `lib/feature_flags/synchronizer.rb` — seeds `self_service` once as before, reconciles `self_service_scope` on every run.
4. `app/controllers/admin/api/v1/features_controller.rb` — the admin toggle takes the scope from the registry, so a row it creates for a fleet-scoped flag does not default to personal settings.
5. `test/lib/feature_flags/synchronizer_test.rb` — seeding, re-scoping, and an admin's `self_service: false` surviving a re-scope.

### Phase 3 — Fleet-scoped self-service API

1. `app/controllers/api/v1/user_features_controller.rb` — `index` lists every self-service flag with `enabled`, `enabledForSelf`, `scope` and the granting `fleets`; `enable`/`disable` toggle the user's own actor for any self-service flag but 403 once one of their fleets grants it (D6).
2. `app/policies/fleet_policy.rb` — `manage_features?`.
3. `app/controllers/api/v1/fleet_features_controller.rb` + `app/views/api/v1/fleet_features/index.jbuilder` — index/enable/disable on the fleet actor.
4. `config/routes/api/fleets_routes.rb` — `/fleets/:slug/features` with the two member `put`s.
5. `app/api_components/v1/schemas/fleet_feature.rb`, `scope` added to `user_feature.rb`, `features` added to `app/api_components/v1/schemas/fleets/fleet.rb`.
6. `app/controllers/api/v1/features_controller.rb` — union deleted.
7. `app/models/fleet.rb` — `Fleet#features`.
8. `app/views/api/v1/fleets/_fleet.jbuilder` — `json.features`, outside `json.cache!`.
9. Integration tests: `fleets_features_{index,enable,disable}_test.rb` (24 cases), plus new cases in `features_test.rb`, `fleets_show_test.rb`, and all three `user_features_*` tests.
10. `./bin/generate-schema` + Orval.

### Phase 4 — Frontend

1. `app/frontend/frontend/composables/useFeatures.ts` — `isFleetFeatureEnabled(fleet, flag)`.
2. `app/frontend/frontend/components/FeatureGuard.vue` — optional `fleet` prop.
3. `app/frontend/typings.d.ts` — `featureScope?: "fleet"` route meta.
4. `app/frontend/frontend/plugins/Router.ts` — the guard consults the route's fleet when the route declares the fleet scope.
5. `app/frontend/frontend/pages/fleets/[slug]/logistics.vue`, `members/index.vue`, `members/starmap.vue`, `members/routes.ts` — fleet-aware reads.
6. `app/frontend/frontend/pages/fleets/[slug]/settings/features.vue` + `settings/routes.ts` — the tab, `access: ["fleet:manage"]`.
7. `app/frontend/frontend/pages/settings/features.vue` — a fleet-scoped row is still toggleable for the viewer alone, marked "Fleet feature"; once a fleet grants it the row reads "Enabled by fleet", names the fleets as links, and the switch is disabled.
8. Translations for `nav`, `headlines`, `labels.features.{fleetSettingsIntro,fleetManaged,fleetManagedInfo}` and the empty state across all seven locales.
9. `app/frontend/frontend/plugins/Router.spec.ts` — four cases for the fleet-scoped guard.

## Intent Verification

- [ ] **Registry expresses toggle ownership** — `bin/feature-flags validate` accepts `self_service: fleet`, rejects `self_service: squadron`
- [ ] **`fleet_logistics` is fleet-scoped** — absent from `GET /user-features`; `hangar_inventories` and `ship_inventories` still present
- [ ] **Personal settings cannot toggle it** — `PUT /user-features/fleet_logistics/enable` returns 403
- [ ] **Personal preview survives** — a member may enable a fleet flag for themselves; the fleet actor and other members are untouched
- [ ] **A fleet grant reads as enabled and cannot be overridden** — the row shows enabled, names the granting fleets, and `enable`/`disable` return 403
- [ ] **A fleet admin can toggle it** — `PUT /fleets/:slug/features/fleet_logistics/enable` succeeds for `fleet:manage`, 403 for a plain member
- [ ] **No cross-fleet leak** — with the flag on for fleet A only, `GET /features` omits it and fleet B's payload reports `features: []`
- [ ] **Flag state is not cached** — toggling for a fleet changes the next `GET /fleets/:slug` without touching the fleet record
- [ ] **The tab appears per fleet** — logistics renders on fleet A, not on fleet B
- [ ] **Features tab is admin-only** — present in fleet settings for `fleet:manage`, absent otherwise

## Key files

| File | Role |
|------|------|
| `config/feature_flags.yml` | Registry — gains the `self_service` scope value |
| `lib/feature_flags/{definition,registry,synchronizer}.rb` | Parse, validate and reconcile the scope |
| `app/models/feature_setting.rb` | Persisted self-service state, now scoped |
| `app/controllers/api/v1/features_controller.rb` | Drops the cross-fleet union |
| `app/controllers/api/v1/user_features_controller.rb` | User-scoped flags only |
| `app/controllers/api/v1/fleet_features_controller.rb` | New — fleet-scoped self-service |
| `app/models/fleet.rb` | `features` + the `fleet:manage` privilege |
| `app/views/api/v1/fleets/_fleet.jbuilder` | Exposes `features` outside the cache block |
| `app/frontend/frontend/composables/useFeatures.ts` | Fleet-aware flag resolution |
| `app/frontend/frontend/pages/fleets/[slug]/logistics.vue` | Gates on the fleet's flags |
| `app/frontend/frontend/pages/fleets/[slug]/settings/features.vue` | New — the tab |
| `app/frontend/frontend/pages/settings/features.vue` | Template for the tab |

## Not in scope (deferred)

- **Migrating existing user-actor gates on `fleet_logistics`** — anyone who already self-enabled it keeps the gate until an admin clears it at `/admin/features`. Worth a follow-up cleanup once the fleet toggle is live, but silently revoking access on deploy is worse than a stale gate.
- **Making the other fleet flags fleet-scoped** — `fleet_starmap` and `fleet_worldmap` are not self-service at all today. Once the mechanism exists, declaring them is a one-line change and a separate decision.
- **A `fleet:features:manage` privilege** — see D7.
- **Admin UI scope display** — `/admin/features` will keep showing a single self-service toggle; surfacing the scope there is cosmetic.

## Discovery Log

- **2026-08-18** Initial research and plan creation. Established that the fleet-actor half of the gate already exists (`Api::BaseController#feature_enabled?`, tested in `test/integration/api/v1/fleets_inventories_index_test.rb:66-91`), so this issue is about ownership and resolution, not about teaching the backend to read a fleet flag. Found the cross-fleet union in `FeaturesController#show` and the `json.cache!` hazard in `_fleet.jbuilder`.
- **2026-08-18** Two things the plan had not accounted for surfaced during implementation, both recorded above as D5 and in Phase 2:
  - The admin view asks "is this flag self-service?" with no surface in mind, which a required `scope:` keyword cannot answer — hence `self_service_anywhere?` rather than making the scope optional everywhere.
  - Deleting the union would have switched `fleet_starmap`/`fleet_worldmap` off for any fleet gated on the fleet actor, because the union was the only path carrying those to the frontend. Fixed by making every fleet-page read fleet-aware, not just `fleet_logistics`.
- **2026-08-18** The personal-settings side went through three revisions before landing, all recorded in D6:
  1. Fleet-scoped flags were dropped from Settings → Features entirely. Too blunt — it hid the feature's existence from the very members who would ask about it.
  2. Listed read-only. Also wrong: it removed a legitimate path, since a user-actor gate is a preview for one person and never switches the feature on for the fleet. The framing in problem 2 above overstated the defect.
  3. Landed: the personal toggle stays for previewing, the fleet tab is the fleet-wide switch, and a fleet's grant wins — reported as enabled, attributed to the fleets responsible, and not overridable per user.

## Progress

- [x] Phase 1 — Registry scope
- [x] Phase 2 — Persist the scope
- [x] Phase 3 — Fleet-scoped self-service API
- [x] Phase 4 — Frontend
