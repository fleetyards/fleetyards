# Visual tests — co-located demos, the gating fix, and coverage gaps

## Goal

Move the demo pages next to the components they document, gate them so they are
visible in dev and on stage but stripped from live, close the component coverage
gaps, and settle the Storybook question with a written decision.

## Context

Three separate things currently wear the name "visual test":

1. **The gallery** — 13 pages under `app/frontend/frontend/pages/visual-tests/`
   (~4,200 lines), mounted into the real router and gated at
   `app/frontend/frontend/pages/routes.ts:9-20`. Human-eyeball surface.
2. **Behaviour specs** — `test/playwright/e2e/{Buttons,Chips,Panels}.spec.ts`.
   DOM, ARIA and state assertions. No pixels.
3. **Pixel baselines** — not on `main`. They live on `parked/visual-baselines`
   (4 commits, 37 behind): `bin/visual-baselines`,
   `.github/workflows/visual.job.yml`, container-rendered PNGs for the admin
   charts, `test/playwright/support/host-proxy.cjs`.

### The gate does not do what it reads like

`routes.ts:10` tests build-time `process.env.NODE_ENV`. Two facts make that
value a constant:

- Vite forces `NODE_ENV=production` for any build when it is not already set
  (`vite/dist/node/chunks/node.js:36479`).
- The Dockerfile never sets `NODE_ENV`. It sets only `ARG RAILS_ENV`
  (`Dockerfile:28`), then runs `bin/rails assets:precompile` (`Dockerfile:89`).

So the expression compiles to `"production"` on stage exactly as on live, and
**the gallery is stripped on stage today.** The `vite.config.ts:124` define
`"process.env": {}` is a red herring — Vite's own define map carries a separate,
more specific `process.env.NODE_ENV` key that survives the user override
(`node.js:25229-25262`).

### Vite mode is the flag that distinguishes the environments

`vite_rails/config.rb:12` sets `mode: Rails.env.to_s`, and stage builds its own
image with `builder.args.RAILS_ENV: staging` (`config/deploy.stage.yml`; CI tags
it `stage-${sha}` in `.github/workflows/deploy-stage.yml`). So:

| Environment | Vite mode | Gallery should be |
|---|---|---|
| dev | `development` | visible |
| e2e / CI | `test` | visible |
| stage | `staging` | visible |
| live | `production` | stripped |

`import.meta.env.MODE !== "production"` satisfies all four. There is precedent
for build-time env gating inside a base component already:
`app/frontend/shared/components/base/BtnGroup/index.vue:53` uses
`import.meta.env.DEV`.

### The gating contradiction this also fixes

`test/playwright/e2e/Chips.spec.ts:8-11` documents it: assertions run against
`/hangar/chips/` rather than `/visual-tests/chips/` because the gallery routes
are stripped from the production build the e2e run uses. Same for
`Buttons.spec.ts` (`/ships/`) and `Panels.spec.ts` (`/`). So specs carry
incidental page setup (`Chips.spec.ts` needs the `chips` Rails scenario and a
public hangar), break when unrelated page work moves a component, and cannot
reach error, empty or loading states at all. Under a `MODE` gate the e2e build
keeps the routes and the specs can target them directly.

## Decisions

**Co-locate the demos with the components.** `Btn/visual.vue` next to
`Btn/index.vue`, rather than a central `pages/visual-tests/` tree. A component
and its demo move, review and rot together.

**Keep a thin central route index** with explicit imports rather than
`import.meta.glob`. Route names stay stable for the e2e specs, and the gated
branch stays a single array that is trivially dead-code eliminated.

**Gate on `import.meta.env.MODE`,** per the table above.

**Keep the gallery in-app. Do not migrate to Storybook.** The pages render
inside the real shell — real global SCSS, real background (`bg-7`), real
stacking contexts, real router and query client. Storybook's iframe cannot
reproduce that, so it structurally cannot see global-CSS collisions, z-index and
layout problems, or things like the modal actions sitting outside the panel.

The clearest example is `states.vue:227-241`: the `FetchProgressBar` section has
no props to set. It renders a button that refetches a real query and lets the
app-wide bar respond to the in-flight count. No story does this.

**Storybook stays open, scoped to `shared/components/base/` only** (26
components, near-zero mocking cost — the whole gallery imports just four
composables/stores). Deferred, not rejected; see Not in scope.

## What remains

### Phase 0 — Verify the strip drops the chunks — DONE, it does

Ran `pnpm exec vite build --mode production` with `NODE_ENV` unset, matching the
Docker build (`Dockerfile` sets only `ARG RAILS_ENV`).

**Result: the gate works.** The route table and all 13 page chunks are gone.

- No `/visual-tests/` path anywhere in the output — the gated array in
  `pages/routes.ts` is eliminated, and `pages/visual-tests/routes.ts` with it.
- Content strings from five different pages (`Panel Error Animated`,
  `Heading | Sizes`, `Sync modal states`, `Notification types`,
  `Model Metrics`) all return zero hits, so the lazy chunks were never emitted.

**One residue: `VisualTestsNav` ships in production.** All 13 route names and
their `nav.visualTests.*` labels are in the main `frontend` chunk — ~5.2KB of a
91KB chunk. `Navigation/index.vue:17` imports it statically and guards it only
with a runtime `v-if` at line 118, so the build cannot drop it. Harmless (the
links render nowhere) but it is dead weight and it advertises the routes.

This also explains the local `public/vite` puzzle from earlier: the
`visual-tests-panels` string in a production bundle comes from this nav
component, not from a leaked route table. Nothing was ever misbuilt.

Two more copies of the same gate live in that file — `Navigation/index.vue:43`
and `:47` — and need the same treatment as `routes.ts:10` in Phase 1.

### Phase 1 — Switch the gate — DONE

`process.env.NODE_ENV` replaced with `import.meta.env.MODE` at all three sites:
`pages/routes.ts:10`, and the two runtime checks in
`components/Navigation/index.vue`. `VisualTestsNav` went from a static import to
a gated `defineAsyncComponent`, and `shouldVisualTestsRouteBeVisible` — a value
that cannot change during a session — became a plain const, `visualTestsEnabled`.

Verified by building both ways:

- **`--mode production`: fully stripped.** No route path, no route names, no page
  chunks, and the nav component is gone — the 5.2KB Phase 0 measured is down to
  nothing. The only residue is the `visualTests` translation keys, which ride
  along in the bundled locale data for all eight languages. That is how
  translations are bundled, not a code leak, and Crowdin owns those files.
- **`--mode test`: fully present.** Route path, all route names and the page
  chunks (`panels-*.js`) are in the output.

The second half is what actually unblocks CI, and it is worth being precise
about where the old gate failed. Locally, `playwright.config.ts` runs the Vite
**dev server**, where `NODE_ENV` is `development`, so the gallery routes existed
and a spec pointed at them passed. CI has no dev server — `e2e.job.yml:62` runs
`assets:precompile`, and any Vite *build* sets `NODE_ENV=production` whatever the
mode. So the old gate stripped the gallery in CI only, and a spec pointed at it
passed on a developer's machine and failed on the branch.

### Phase 1b — Re-point the specs: one of three moved

`Buttons.spec.ts` moved to `/visual-tests/buttons/`. The page turned out to be
purpose-built for it: `buttons.vue:192-202` carries a `data-test="group-with-label"`
group holding a bare label span and a disabled arrow, commented as "the shape the
paginator uses". So the `.pagination` locator became that hook, and the `buttons`
Rails scenario and its `app("clean")` are gone from every test but one. The
toolbar assertion stayed on `/ships/` in its own describe — it is about a page
owning the spacing Btn stopped shipping, which no demo page can show.

The other two stay where they are, and this is a coverage gap rather than a
gating one:

- **`Chips.spec.ts`** — every assertion is about state that round-trips through
  the query string (`hangarGroupsIn`, `hangarGroupsNotIn`, the `useFilters`
  debounce). `chips.vue` renders `ChipRow` over a static array with no filters
  store and no router behind it. Moving it means wiring real filter state into
  the demo page.
- **`Panels.spec.ts`** — `panels.vue` does render `ModelPanel`, but through a
  live `useModel("galaxy")` query, so the seeded-data dependency does not go
  away, it just changes shape. The assertions need a card whose whole height
  comes from a background image, which requires the fixture behind it to carry a
  store image.

Both comments were corrected to say this, since both previously claimed the
routes are stripped from any production build.

Revisit after Phase 4 adds the missing states — that is what these two are
actually waiting on.

**Verified: 11/11 green, and roughly ten times faster.** Each gallery test runs
in ~200ms against precompiled assets where the seeded ships list cost 2-3s, and
the whole file finishes in 11.5s.

Run it the way CI does — `CI=1 pnpm exec playwright test ...` — or the result
misleads you. Without `CI`, `playwright.config.ts` starts a Vite **dev server**,
and the gallery route pulls a module graph big enough that a cold
`domcontentloaded` measured **56 seconds**, past the 60s test timeout. Editing
anything every page imports (`Navigation/index.vue` did it here) invalidates that
graph, so the next local run pays the full cost and the spec reads as hanging on
`page.goto`. CI never sees this: `e2e.job.yml` precompiles and serves built
chunks, which is what the 11.5s above measures.

Worth knowing separately: `/health_check` — the URL `playwright.config.ts` waits
on to decide the server is up — did not respond at all while the Rails test
server was busy. It resolved once the server was idle. Not investigated, and not
caused by this work, but it is a plausible source of flaky CI startup.

### Phase 2 — Co-locate the single-owner demos — DONE

A demo now lives beside the component it documents, but only where **exactly
one** component owns it. Three moved:

| Was | Now |
|---|---|
| `pages/visual-tests/chips.vue` | `shared/components/base/Chip/visual.vue` |
| `pages/visual-tests/notifications.vue` (+ `CtaDemo`, `ImageDemo`) | `shared/components/AppNotifications/visual.vue` (+ `visual/`) |
| `pages/visual-tests/sync-modal.vue` (+ `StatePreview`) | `frontend/components/Hangar/SyncBtn/Result/visual.vue` (+ `visual/`) |

Route names and paths are unchanged, so nothing outside the route index moved
with them.

**What stayed, and why.** A page covering a whole family has no single owner:
`buttons.vue` documents Btn, BtnGroup and BtnDropdown, so filing it under `Btn/`
would hide the other two from whoever changes them. Same for `tables.vue`
(Table, Table2) and `panels.vue`. The composed pages — `forms.vue` at 13
components, `lists.vue`, `states.vue`, `metrics.vue`, `events.vue`,
`typography.vue` — have no owner at all.

`support-hint.vue` is the interesting one. It renders the hint in its real
context, inside the sync result panel, so it imports `StatePreview` from a
`frontend/` component. Co-locating it under `shared/components/SupportHint/`
would have made `shared/` depend on `frontend/`, so it stays where it is.

**The auto-scan needed the exclusion Phase 2 predicted.** Without it,
`Chip/visual.vue` was registered globally and written into `components.d.ts` as
`ChipVisual` — confirmed, then fixed with `globsExclude: ["**/visual.vue",
"**/visual/**"]` on the `Components()` plugin. Those patterns become the glob's
`ignore` list, so no `!` prefix.

**A lint rule replaces the safety the single directory used to give.**
`no-restricted-imports` on `**/visual.vue` and `**/visual/*`, exempting the
route index, the demos themselves and the pages under `visual-tests/`.
Verified in both directions: it fires on a real import from `pages/index.vue`,
and every legitimate importer stays clean.

**knip needed nothing.** It follows the route index, so no demo is reported
unused. It does exit 1 on this repo, but on pre-existing findings — 23 unused
files, none of them mine — and it is not wired into CI.

Verified: `--mode production` drops every moved demo (checked on strings unique
to them, not on words the real components also render), `--mode test` keeps
them, and all three routes render with no page errors. 32 specs green.

Worth knowing for any future check like this: `vite.config.ts` sets
`build.emptyOutDir: false`, so stale chunks from earlier builds stay in
`public/vite*`. A grep there proves nothing unless the directory is removed
first — a `chips-*.js` from before the move was still sitting in the test build.

### Phase 3 — Cover the missing components

Two base components have no demo at all: `FormDateTime`, `FormTabs`.

Uncovered in `shared/components/`:

| Component | Note |
|---|---|
| `Chart` | Highcharts wrapper. Highest value — see `parked/visual-baselines` and the ESM/UMD dual-instance trap |
| `Avatar`, `LazyImage`, `ViewImage`, `Video` | Media states: loading, broken, missing |
| `StatsPanel`, `TeaserPanel`, `TeaserPanel2` | Panel variants `panels.vue` does not reach |
| `Markdown` | User-supplied content — the states worth pinning are the hostile ones |
| `OffCanvas`, `AppConfirm`, `BreadCrumbs`, `TabNavView` | Navigation and overlay chrome |
| `SocialLogins`, `OauthBtn`, `RsiProfileLink`, `CommunityLogo` | Third-party branding, easy to break unnoticed |
| `HoloViewer`, `LoadoutMarker` | 3D/canvas — may not suit a static demo |
| `PrimaryAction`, `UploadProgress`, `Forbidden`, `ModelMetricRows` | Small, cheap |
| `AppNavigation`, `AppFooter`, `AppEnvironment`, `BackgroundImage` | Always-on in the shell; probably skip |

`FetchProgressBar` has a section but no import — it is driven globally, which is
correct, not a gap.

Judgement call, not a checklist to clear: decide per row and record the skips.

### Phase 4 — State, variant and viewport coverage

Presence is not state coverage. The demos lean happy-path. Per family:

- Every form control: default, filled, disabled, readonly, error, and
  error-plus-filled. `forms/ErrorStates.vue` does this for a subset only.
- Lists and tables: populated, empty, loading, error, single-row, and one
  overflow case (long labels, many columns).
- Async: `Loader`, `SmallLoader`, `ProgressBar`, `Paginator` at boundaries —
  page 1, last page, one page.

Missing entirely: **narrow viewports.** Every page is written for desktop width
and `visual-compare.spec.ts` only ever set 1440×900, so responsive regressions
are invisible to both the gallery and the suite.

### Phase 5 — Unpark the pixel baselines

Rebase `parked/visual-baselines` onto main (37 behind; expect conflicts in
`playwright.config.ts` and `package.json`), then re-target it from the admin
charts onto the now-reachable demo routes.

The three constraints from that branch still hold and are the expensive part —
Linux-only baselines with no platform suffix, a future-dated frozen clock, and
`maxDiffPixels: 0` rather than a ratio. Component-scoped screenshots make the
strict threshold practical: 0.2% of a full-page shot is ~575px of slack, and a
real regression measured 371.

The admin area has 76 components and no gallery. Out of scope here; the parked
branch's chart baselines are its only coverage.

## Key files

- `app/frontend/frontend/pages/routes.ts:9-20` — the gate to change
- `vite.config.ts:124` — the `process.env` define; `Components({ dirs })` above it
- `app/frontend/frontend/pages/visual-tests/` — 13 pages plus `routes.ts`
- `app/frontend/frontend/components/Navigation/VisualTestsNav/index.vue`
- `test/playwright/e2e/{Buttons,Chips,Panels}.spec.ts` — specs to re-point
- `config/deploy.stage.yml` — `builder.args.RAILS_ENV: staging`
- `test/playwright/visual-compare.spec.ts` — one-off before/after script from the
  bootstrap removal, hardcoded to `fleetyards.test` and `localhost:8540`. Dead;
  delete it or move it out of `test/playwright/`
- `parked/visual-baselines` — `bin/visual-baselines`,
  `.github/workflows/visual.job.yml`, `test/playwright/support/host-proxy.cjs`

## Not in scope (deferred)

- **Storybook for `shared/components/base/`.** Revisit once Phase 1 lands and we
  know whether prop-matrix coverage is still what we are missing. Cost is a
  second Vite pipeline duplicating a Rails-integrated config (`bin/vite`,
  orval-generated clients, aliases, SCSS, i18n) that will drift, plus a large
  dependency tree in an already busy Dependabot queue.
- **Chromatic** or any hosted diffing that ships screenshots to a third party.
- **An admin gallery.** Real gap, separate piece of work.

## Progress

- [x] Phase 0 — Verified: a production build drops the route table and all 13 page chunks
- [x] Phase 1 — Gated on `import.meta.env.MODE` (3 sites); verified stripped in
      production mode and present in test mode
- [~] Phase 1b — `Buttons.spec.ts` re-pointed at the gallery, 11/11 green CI-style;
      `Chips` and `Panels` blocked on demo-page data wiring, see Phase 4
- [x] Phase 2 — Co-located the three single-owner demos; auto-scan exclusion and
      lint rule in place, family and composed pages left central
- [ ] Phase 3 — Demos for the uncovered components
- [ ] Phase 4 — State, variant and narrow-viewport coverage
- [ ] Phase 5 — Rebase and re-target the pixel baselines
