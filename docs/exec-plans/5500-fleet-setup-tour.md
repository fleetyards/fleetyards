# Step-by-step tour for setting up a new fleet

Working plan for #5500. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Someone who just created a fleet is walked across the fleet's pages, from the overview to the settings, with each step pointing at the control that sets that part up.

## Open questions

- None.

## What changed

### Phase 1 — Route-bound steps in `Tour`

1. `TourStep.route`: before showing the step, forwards or back, the tour navigates there if it is elsewhere, hides the card, and polls for the target (100 ms, up to 5 s).
2. A required target that never renders is passed over, in the direction of travel. An optional one leaves its card centred.
3. Next / Back are ignored while a step's page is loading. The step-list watch follows `props.steps`, not `shown`, so passing over a step does not re-show the current one.
4. The router is injected (`routerKey`) rather than `useRouter()`, so a page-bound tour still works without one.

### Phase 2 — Fleet tour

1. Steps and pages:
   - welcome, events and contracts on the overview. Events and contracts are nav tabs, flag-gated and required.
   - members: invite
   - ships: fleetchart
   - settings: membership (ships filter), RSI (SID and verify), roles (first role), squadrons (switch), Discord (bot install link), fleet (public toggle)
2. Each target is a `data-tour` attribute on its page. `FleetNav` carries `fleet-events` / `fleet-contracts` on desktop only: on a phone it is the slide-out menu, laid out off-screen while closed, and the bottom bar carries them instead.
3. `FleetTour` is mounted once by `App.vue`, outside the `router-view`, and reads `fleetStore.tourFleet` / `tourOpen`. It closes when the route leaves that fleet.

### Phase 3 — When it shows

1. `fleetStore.pendingTours` (persisted, `userId:fleetId` → queued at) is set by `fleets/add.vue` after a successful create, and cleared when the tour starts. An entry lapses after seven days and is pruned on the next queue.
2. The overview autostarts it while it is pending and the viewer is an accepted member with `capabilities.manageFleet`, the capability behind the settings routes' `fleet:manage`.
3. "Show tour" goes in `#header-right` on the overview (icon-only on mobile), for managers only.

### Phase 4 — Copy

`texts.fleetTour.*` in de, en, es, fr, it, zh-CN, zh-TW, inserted as text after `hangarTour`.

## Intent Verification

- [x] **Walks the fleet's pages**: `e2e/FleetTour.spec.ts` asserts the step and the URL at every step, overview to `settings/fleet/`.
- [x] **Route-bound steps**: `Tour/index.spec.ts` "Tour across pages" covers navigating, waiting, passing over, Back to the previous page, and Next ignored while loading. The e2e covers Back too.
- [x] **Managers only, once after creating, replayable**: `pages/fleets/[slug]/index.spec.ts`, `add.spec.ts`, and the e2e (create → skip → no restart → replay).
- [x] **Flag-gated steps skipped**: events and contracts are the only required steps (`Fleets/Tour/index.spec.ts`); off in the e2e, absent from the walk.
- [x] **All 7 locales**.

## Key files

| File                                                     | Role                                          |
| -------------------------------------------------------- | --------------------------------------------- |
| `app/frontend/shared/components/Tour/index.vue`          | route-bound steps                             |
| `app/frontend/frontend/components/Fleets/Tour/index.vue` | steps, pages, closes off the fleet            |
| `app/frontend/frontend/App.vue`                          | mounts the fleet tour outside the router-view |
| `app/frontend/frontend/pages/fleets/[slug]/index.vue`    | access check, autostart, tour button          |
| `app/frontend/frontend/stores/fleet.ts`                  | `pendingTours`, `tourFleet`, `tourOpen`       |
| `test/playwright/e2e/FleetTour.spec.ts`                  | the walk, Back, start once, replay            |

## Not in scope (deferred)

- None.

## Discovery Log

- **2026-10-08** `NavItem`'s fallthrough attributes reach the `<li>` in the `router-link` branch as well (`custom` renders a single vnode), so `data-tour` needs no new prop.
- **2026-10-08** A fleet created with an SID lands on `settings/rsi`, not the overview. The tour stays pending until the overview is next opened.
- **2026-10-08** `Fleet.spec.ts` clicked the nav after creating a fleet, which the auto-started tour would have blocked. Both flows now skip the tour first.
- **2026-10-08** Review: on mobile the closed slide-out menu still has client rects and precedes the bottom bar, so the tour spotlighted tabs off-screen. Pending tours never expired.
- **2026-10-08** The issue now decides on a tour across the fleet's pages, not overview-only.
- **2026-10-08** The fleet layout does not survive navigation: `App.vue` keys its page by path (`pageKey`), so the whole fleet tree remounts on each route change and took the tour with it.
- **2026-10-08** A role's panel is taller than the window; the roles step spotlights its heading. Its rights are read-only on that page, so the copy says what the page shows rather than how to edit.

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
