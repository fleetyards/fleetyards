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

### Phase 3 — Cover the missing components — STARTED, 3 of 27

Done, highest value first:

- **`Chart`** — new co-located `shared/components/Chart/visual.vue`, on its own
  `/visual-tests/charts/` route. Seeing the states side by side showed that two
  of them said nothing at all: a failed chart drew no axes and put no message in
  their place, and a settled chart with an empty series was left to Highcharts,
  which drew a bare pair of axes that reads as a chart that broke. Both now say
  which they are, and a failure offers a retry when the status carries a
  `refetch`. Guarded by `Charts.spec.ts`. All five Highcharts types, a flat series, a
  single-slice pie, and the async states driven by a hand-built `asyncStatus`
  bag: pending, failed, and the refetching case the component's own comment
  calls out (the drawn chart must stay, with no spinner over it). Plus the admin
  palette and a redraw button, because Highcharts holds its instance outside
  Vue's control. Verified: 10 chart roots draw with no page errors, which also
  exercises the ESM core plus a11y module import in a real build.
- **`FormDateTime`** and **`FormTabs`** — the two base components that had no
  demo at all. Both went into `forms.vue` rather than beside their component:
  form controls are compared side by side, so the family page is where they
  belong. FormTabs needs a vee-validate context to show its error marker, so it
  lives in `forms/TabsDemo.vue` next to `ErrorStates.vue`, using the same
  validate-on-mount trick.

A new route needs four things, not one: the entry in
`pages/visual-tests/routes.ts`, a `NavItem` in `VisualTestsNav`, and keys under
`visualTests` in `en/{headlines,nav,title}.json`. English only — `crowdin.yml`
makes `en` the source and propagates the rest.

**`FormTabs.spec.ts` is new**, and it is the first spec written *because* the
gate and the demos now work. It asserts what a screenshot cannot: that a tab is
marked invalid only for its own fields and never inherits a sibling's failure,
that a disabled tab is out of the tab order and refuses activation, that a
hidden tab is absent from the strip rather than disabled in it, and that the
active tab round-trips through `?demotab=`. No seeded data, so no scenario.
The real hooks are `data-test="tab-anchor-<id>"` with `has-errors` / `disabled`
/ `active` classes on `TabNavView/AnchorItems`.

**The media group is covered too** — `Avatar`, `LazyImage`, `ViewImage` and
`Video`, on one central `media.vue` page. Four separate owners, so by the Phase 2
rule it stays central rather than being split four ways, and it joins the
Foundations submenu.

They share one problem, which is what makes them a group: what they show when the
image is not there. Each answers differently — a bundled placeholder, an icon, or
nothing at all — and writing the page corrected a belief worth recording:
**LazyImage's error fallback is the same bundled placeholder as its missing-src
fallback**. A broken URL and a URL that was never set are therefore
indistinguishable by eye; only the `--error` class separates them. The first
draft of the page claimed the browser was left with a broken image, which was
simply wrong.

`Media.spec.ts` covers that, plus the one that matters beyond looks: **no YouTube
iframe exists before consent** — absent, not hidden — and it reappears only after
the visitor agrees.

**The page found three real bugs, two in `Video` and one in `Avatar`.** This is
the payoff of putting a component somewhere it can be looked at.

First, the consent prompt's two buttons touched: `.youtube-placeholder-buttons`
carried no rules at all and `Btn` ships no margin, so "Allow video embeds" and
"Copy Youtube URL" read as one control. Caught by `VisualTestsSpacing.spec.ts`.

Second, and worse: **the video box had no height.** The markup still carries
Bootstrap's `embed-responsive embed-responsive-16by9` and `embed-responsive-item`
class names, but only `.embed-responsive` survived the Bootstrap removal — with
its cosmetics and none of its geometry, so no `position: relative` and no aspect
ratio. Both the iframe and the consent placeholder collapsed to nothing.
`Video` is rendered by `pages/ships/[slug]/videos.vue` and
`components/Hangar/GuideModal`, neither of which supplies a size, so this was
invisible in production. Restored with `aspect-ratio` rather than Bootstrap's
padding-bottom hack, which depended on the `height: 0` the class no longer sets.

Both fixed in `stylesheets/frontend/partials/media.scss`. The embed app carries
the same dead rules but never renders `Video`, so it was left alone.

Third, spotted by eye on the rendered page: **`Avatar` had no error state.** It
falls back to an icon when there is no avatar, but a URL that no longer resolves
left the browser rendering the img's `alt="avatar"`, which the round frame clips
into a cropped word. A deleted upload or a CDN miss looked like a rendering
glitch. It now falls back to the same icon, which is what its sibling `LazyImage`
already did — the two were inconsistent.

**The panel variants and `Markdown` are covered.** `StatsPanel`, `TeaserPanel`
and `TeaserPanel2` went onto `panels.vue`, which already had the surrounding
material and a `useModel("galaxy")` query `TeaserPanel2` could be handed
directly. `TeaserPanel` takes a plain shape rather than an API type, so its
fixture is written out in the page.

`Markdown` went onto `typography.vue` — text rendering compared beside the other
text components. Its escaping and its link guard are already covered by
`Markdown/index.test.ts`, so the page shows what is left: whether escaped markup
reads as text rather than a wall of entities, and whether a generated identifier
with nothing to break on bursts its column.

It did. **`Markdown` had no wrapping rule**, and it renders notification bodies
in `admin/pages/notifications.vue` — generated reports full of slugs and ids, in
a narrow panel. Fixed with `overflow-wrap: anywhere` (not `break-all`, so prose
still breaks between words).

Two things worth not rediscovering:

- **A literal `</script>` inside an SFC ends the script block.** The hostile
  markdown sample needs `<\/script>`, and the *comment* explaining it must not
  spell the tag out either — writing it there broke the file a second time.
- **This project's grid breakpoints are much larger than Bootstrap's**: `md` is
  992px and `lg` is **1500px**. A `col-lg-3` is full width on an ordinary laptop,
  so measuring one and finding it container-width is correct, not a broken grid —
  a near-miss here. Demos that need a genuinely narrow column use an
  unconditional `col-6` / `col-3`.

**The overlay and nav chrome is covered** on a new `overlays.vue`:
`AppConfirm`, `OffCanvas`, `BreadCrumbs` and `TabNavView`.

The first two are the reason this page earns its place. Both are singletons
mounted once in `App.vue` and driven by comlink events, so they are only ever on
screen mid-action — the confirm during a destructive click, and the off-canvas on
mobile, since `FilteredList` is the only thing that opens it and only below the
breakpoint. At desktop width there was previously nowhere to look at either. The
page asks the app to show them, and teleports its own content into
`#off-canvas-content`, which is how the off-canvas is filled.

`TabNavView`'s routes mode is fed the real visual-tests route records: it reads
`nav.<meta.title>` for each label and those keys already exist. Its admin stepper
mode is deliberately absent from `BreadCrumbs` here — it targets
`admin-model-edit`, a route this app does not have.

`Overlays.spec.ts` covers what no screenshot can: that Enter confirms and Escape
cancels, that the handler actually runs, that the off-canvas opens on either
side, and that a crumb without a target is not a link.

**This slice found no bugs** — 24 assertions green on the first run. Worth saying
plainly after four slices that each turned one up: the gallery is not a divining
rod, and these four components were simply in good shape.

**The four small ones are covered**, and all four slotted into existing pages, so
no new route, nav entry or translations. `Forbidden` joined the error blocks on
`states.vue`, which were three and should have been four — it is the one for a
resource that exists and is not yours, against `NotAuthorized` for not being
signed in at all. `UploadProgress` joined the progress states, including the
failed-part-way case that has to stay on screen rather than resetting.
`ModelMetricRows` went to `metrics.vue` with its groups written out, since the
demo is about the layout rules. `PrimaryAction` went to `buttons.vue` behind a
toggle and a click counter — it renders nothing without an `action` and floats
fixed, so there is otherwise no way to tell it works.

That last one turned up the worst defect of the run: **`PrimaryAction` was a
`div` with a click handler**, so the hangar's one obvious next step could not be
reached from the keyboard, showed no focus ring and reported no role — the very
defects `Btn` was rebuilt to fix, in the control that matters most on the page.
It renders a `Btn` now. Its circle stays (`Avatar` is round too, so the design
has the shape) but the caps go: a cap is a straight bar meant to close a straight
edge, and rendering all three variants side by side showed that at the default
inset the bars overhang the curve and at 34% they still cross it.

**The branding group is deferred, and the reason is a correction.** The audit
called `SocialLogins`, `OauthBtn`, `RsiProfileLink` and `CommunityLogo` the
cheapest remaining slice. They are the least demo-able: `OauthBtn` only renders
behind a feature flag per provider, clicking one starts a real OAuth flow and
leaves the app, and the interesting states of `SocialLogins` need a session.
Worth a look while there: `OauthBtn` builds its flag name as a string,
`isFeatureEnabled(`oauth-${provider}`)`, which is the one thing the feature-flag
convention says not to do.

Still uncovered in `shared/components/` (8):

| Component | Note |
|---|---|
| `SocialLogins`, `OauthBtn`, `RsiProfileLink`, `CommunityLogo` | Flag-gated, session-gated, and a click leaves the app — see above |
| `HoloViewer`, `LoadoutMarker` | 3D/canvas — may not suit a static demo |
| `AppNavigation`, `AppFooter`, `AppEnvironment`, `BackgroundImage` | Always-on in the shell; skip, they are on screen everywhere |

`FetchProgressBar` has a section but no import — it is driven globally, which is
correct, not a gap.

Judgement call, not a checklist to clear: decide per row and record the skips.
Next: the third-party branding group (`SocialLogins`, `OauthBtn`,
`RsiProfileLink`, `CommunityLogo`) — four cheap components whose breakage is the
kind nobody notices, followed by the four small ones (`PrimaryAction`,
`UploadProgress`, `Forbidden`, `ModelMetricRows`). That would leave only
`HoloViewer` and `LoadoutMarker`, which may not suit a static demo, and the
always-on shell components, which are on screen everywhere already.

### Spacing and grouping — DONE, out of band

Reported from looking at the pages, not found by any of the phases.

**Buttons were touching, in three different ways.** `Btn` ships no margin of its
own — spacing belongs to the container — and several demo containers brought
none. Each round of fixing found a case the previous detection had been blind to:

1. Containers with no spacing parent at all (`AppNotifications/visual.vue`,
   `lists.vue`). Found by searching for adjacent `<Btn>` siblings.
2. `support-hint.vue`, where the buttons come from a `v-for` — one element
   rendering N buttons, so a search for adjacent siblings could never see it.
3. Three paginators stacked in bare rows. A paginator *is* a BtnGroup, so the
   horizontal search skipped it twice over: members of a group are meant to
   touch, but two whole groups are not.

`.vt-row` and `.vt-stack` now live once on the host page, which already owned the
pages' vertical rhythm. Four pages had grown their own copy of `.vt-row`, and
`events.vue`'s copy was quietly different — top-aligned, wider gutter — because
it lays out cards, so it became `.vt-cards`.

Two things deliberately not done. `.row + .row { margin-top }` on the host page
would fix the class in one rule, but the host's styles reach the demos through
`:deep()`, which also reaches inside the real components they render — a gallery
that distorts what it is showing is worse than one with a missing gap. And 153
markup-adjacent button pairs in the real app were left alone: adjacency is not a
missing gap, since dropdowns, `FormActions` and context menus all bring their
own, and confirming a real one means measuring the rendered page.

**`VisualTestsSpacing.spec.ts`** measures instead of reading templates, which is
what catches the `v-for` case, checks both axes, treats a BtnGroup as one
control, and lists every route so a new page cannot be quietly left out.

**The nav is grouped.** Fourteen flat entries became three submenus —
Foundations (typography, panels, buttons, chips), Data (tables, lists, metrics,
charts), Feedback (states, notifications, support-hint, sync-modal) — with Forms
and Events staying top-level, because a group of one is an entry wearing a
folder. A group stays highlighted while one of its pages is open.

The grouping lives in `VisualTestsNav` only; route names and URLs stay flat. One
place to regroup rather than two that drift, and the specs pointing at
`/visual-tests/<name>/` keep working. Nesting the URLs to match is possible
later — it would cost 14 route paths, three spec files and the translations.

**`VisualTestsNav.spec.ts`** guards the invariant that actually breaks: a new
page needs four separate edits — route, nav entry, and keys in
`en/{headlines,nav,title}.json` — and forgetting the nav leaves a page that
exists but cannot be found. So it asserts every route has exactly one nav link,
rather than checking the nav against another copy of the same list.

### The confirm surfaces — rebuilt out of band

Reported from using the pages, and it grew into the largest single piece of this
work. A design concept for it is published as an artifact; the summary:

**`AppConfirm` was a copy of a toast.** The same 325px card, the same shadow, and
the same `scaleY(0.01) translate(30px, 0)` entrance — a movement written for
something arriving in the top-right corner, played on a centred dialog. Plus a
`leave-active { position: absolute }` left over from a list transition, and no
scrim at all. Four bugs, one cause: the dialog was assembled from another
component's parts rather than from the design's vocabulary.

It now follows the app modal — a scrim that fades, a dialog travelling from
`translate(0, -25%)` — with the question in a `Panel` and the actions outside it
as the modal footer does. The accent is the panel's end-caps, which is how this
design carries what a toast carries in its coloured edge.

**Its tones are its own three, not the panel's five.** `neutral` is the default,
so colour is spent only where it means something instead of becoming the
wallpaper of every confirmation; `warning` for what cannot simply be repeated,
`danger` for what does not come back. Only `danger` tones the committing button —
a warning dressed as a danger stops being read.

**`BtnConfirm` is new**: an inline confirm for the decisions a modal is too heavy
for, composed from `Btn` and `BtnGroup` with no new button and one line of CSS of
its own. Armed, the trigger becomes the group's label-segment shape the paginator
already uses, so three segments read as one control.

Five defects surfaced along the way, each of which reads as something else:

- **Both entrances sometimes started mid-screen.** A `setTimeout(50)` that did
  not guarantee the start state was painted, and — for the off-canvas — the side
  class flip itself being animated, so the panel travelled between the two
  off-screen positions and crossed the viewport. Two `requestAnimationFrame`s and
  a suppressed transition while repositioning; `utils/Transitions.ts` holds the
  helper.
- **One `Enter` ran both outcomes**: `autofocus` sat on Cancel while a window
  listener confirmed.
- **The inline confirm's arming click disarmed it**: Vue removes the trigger the
  moment it arms, so the same event reached the document listener with a detached
  target, which `contains()` reports as outside.
- **Its `Escape` never fired**, because the handler was bound inside a component
  whose focused element had just been removed.
- **The question sat high in its panel**: `PanelBody` is 4px top and 18px bottom,
  right under a heading and wrong for a panel holding only a question.

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
- [~] Phase 1b — `Buttons.spec.ts` and `Panels.spec.ts` re-pointed at the gallery
      and off their Rails scenarios; `Chips` still parked, it needs real filter
      state on the demo page
- [x] Phase 2 — Co-located the three single-owner demos; auto-scan exclusion and
      lint rule in place, family and composed pages left central
- [x] Phase 3 — Chart, FormDateTime, FormTabs, media, panel variants, Markdown,
      overlay/nav chrome and the four small ones covered. The 8 left are
      deliberate skips: flag- and session-gated branding, 3D/canvas, and the
      always-on shell
- [x] Spacing fixed (three classes of it) and the nav grouped into submenus,
      both guarded by specs
- [x] Confirm surfaces rebuilt: AppConfirm in the current language with its own
      three tones, a new inline BtnConfirm, and five defects fixed along the way
- [x] PrimaryAction made a real button (it was a div with a click handler)
- [~] Phase 4 — Narrow viewports covered at 390/768/1280 (two real overflow bugs
      fixed), and every bindable form control now shows its invalid state — which
      turned up two controls signalling it by tooltip alone. Left: `Chips` needs
      filter state, plus single-row cases and FilteredList's empty/error states.
      Corrected on the way: no control in this design system has a `readonly`
      state, and the lists and tables already covered empty and loading — the
      plan's expectation there was written before the pages were audited
- [ ] Phase 5 — Rebase and re-target the pixel baselines

## Loose ends, found and left

- **A Postgres deadlock in the test-data reset.** `POST /__e2e__/command` for
  `app("clean")` has failed with `PG::TRDeadlockDetected` in two separate full
  runs, each time passing on retry. Recurring, so not worth calling noise.
- **The event ship card still overflows below ~380px.** Its `min-width: 350px` is
  the floor; lowering a card's minimum legible width is a design decision.
- **`OauthBtn` builds its feature-flag name as a string**,
  `isFeatureEnabled(`oauth-${provider}`)`, which is the one thing the flag
  convention says not to do.
- **The branding group has no demo** — see the Phase 3 note for why it is the
  least demo-able group rather than the cheapest.
