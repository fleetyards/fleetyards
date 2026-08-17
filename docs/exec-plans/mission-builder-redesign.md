# Mission builder redesign

## Goal

Re-concept the mission-builder surface from [#3893](https://github.com/fleetyards/fleetyards/pull/3893)
— fleet events, the calendar, missions, teams, ships, slots and signups — on the
control language that landed **after** the branch was written, so the feature
ships in the design system the rest of the app now uses rather than the one it
was designed against.

Companion to [`btn-redesign.md`](btn-redesign.md), [`panel-redesign.md`](panel-redesign.md)
and [`label-redesign.md`](label-redesign.md). Those three chose the metrics-card
language for the app's controls, surfaces and pills; this plan is the first large
feature to be authored in it rather than migrated to it.

## Context

`feat/mission-builder-v3` opened 2026-05-09 and was last pushed 2026-06-15.
41,194 additions / 4,917 deletions, **282 commits behind `main`**, currently
conflicting. The frontend half is the largest un-landed UI surface in the repo.

Measured surface (66 changed `*.vue` files on the branch, against merge-base
`07a5605`):

| Metric                                       | Count | Files |
| -------------------------------------------- | ----- | ----- |
| `<Btn>` call sites                           | 102   | 31    |
| `<BtnGroup>` / `<BtnDropdown>` call sites    | 9 / 4 | 7 / 4 |
| `<Panel>` call sites                         | 23    | 9     |
| `<PanelHeading>` / `<PanelBody>`             | 17/18 | 5 / 6 |
| `<style lang="scss" scoped>` blocks          | 45    | 45    |
| `:deep(.panel*)` selectors                   | 18    | 5     |
| Hand-rolled `<section>` / `<h3..h5 class>`   | 35    | 15    |
| `data-test` hooks                            | **4** | 3     |
| `aria-label`                                 | **6** | 4     |

The 40 new components split into three families — `Fleets/Events` (24),
`Fleets/Missions` (9), and shared pickers/modals (7) — behind 25 new pages.

## Findings that drive the design

### F1 — Every `Btn` call site is on the retired prop API

| Branch usage                                    | Count | New form                |
| ----------------------------------------------- | ----- | ----------------------- |
| `inline`                                        | 124   | **removed** (no margin) |
| `BtnSizesEnum.SMALL` (66) + `size="small"` (20) | 86    | *omit* — `sm` is default |
| `BtnSizesEnum.LARGE`                            | 8     | `lg`                    |
| `variant="link"` (18) + `BtnVariantsEnum.LINK` (2) | 20 | `variant="bare"`        |
| `variant="danger"`                              | 8     | `tone="danger"`         |

Mechanical, and it *deletes* props rather than adding them. Two hazards:

- The enum members (`SMALL`, `LARGE`, `LINK`) no longer exist, so TypeScript
  catches those 96 sites at build. Good.
- **`inline` does not error.** It is not a declared prop any more, so Vue passes
  it through `v-bind="$attrs"` onto the element as a DOM attribute. All 124 sites
  compile, render, and silently emit `inline="true"` into the markup. Nothing
  fails; nothing is styled either.

`size="xs"` did not exist when the branch was written and is the size several of
these surfaces actually want — see D4.

### F2 — Five components restyle `Panel`'s internals, and the selectors are half dead

18 `:deep(.panel*)` rules across `EventPanel`, `EventShipCard`,
`MissionPanel`, `ShipCard` and `CalendarGrid`. The new `Panel` is **one box**
where the old one was three, and the class names moved with it:

| Selector used         | Still exists on `main`?              |
| --------------------- | ------------------------------------ |
| `:deep(.panel-bg)`    | yes — `Panel/BgImage`                |
| `:deep(.panel-body)`  | yes                                  |
| `:deep(.panel-heading)` | yes                                |
| `:deep(.panel-inner)` | **no** — now `.panel__inner`         |

So `EventPanel`'s cover treatment *half*-applies. This:

```scss
.event-panel :deep(.panel-bg)    { height: 200px; bottom: auto; }
.event-panel :deep(.panel-inner) { padding-top: 200px; }          // dead
.event-panel :deep(.panel-heading) { position: absolute; height: 200px; }
```

gives the image its height, never gives the content its offset, and drops an
absolutely-positioned 200px heading on top of the body copy. `EventShipCard`
fails the same way at 160px.

The fix is already a first-class API. The new `Panel` ships:

```css
.panel--has-bg > .panel__inner { min-height: var(--panel-image-height, 286px); }
```

— added, per the panel plan, *specifically* so a consumer never reaches in. Each
card's four deep selectors collapse to one custom property and a
`PanelHeading shadow="top"`, whose scrim gradient and inner radius are what the
hand-rolled absolute positioning was emulating.

Related: `EventShipCard` rounds its placeholder and slot band with
`$panelInnerBorderRadius` (20px) inside a panel whose inner radius is now
`--radius-surface-inner` (14px) — a 6px overhang on two corners.

### F3 — The feature invented a second design system, on undeclared properties

| Property                | Occurrences | Files | Declared anywhere? |
| ----------------------- | ----------- | ----- | ------------------ |
| `var(--text-muted)`     | 60          | 23    | **no**             |
| `var(--accent, #4aa)`   | 28          | 17    | **no**             |
| `var(--text)`           | 9           | 8     | **no**             |
| `var(--warning\|success\|danger\|border\|primary…)` | 26 | 14 | **no** |

None of `--text-muted`, `--accent`, `--text`, `--border`, `--warning`,
`--success` or `--danger` is declared in `app/frontend` on this branch. The
consequences differ by whether a fallback was written:

- **`var(--text-muted)` — no fallback at any of the 60 sites.** The declaration
  is invalid at computed-value time, so every "muted" caption, hint, label and
  timestamp in the feature inherits full `--color-text` instead. The visual
  hierarchy the markup describes does not render.
- `var(--accent, #4aa)` renders the literal. Teal, at 28 sites. The button plan's
  D6 settled this explicitly: *"the interactive accent is `$primary` blue, not
  cyan"*.
- `var(--warning, #ff9800)`, `var(--success, #4caf50)`, `var(--danger, #c66)`
  render literals that are **not** the app's tokens (`#fa6800`, `#5cb85c`,
  `#dc3545`).

The app's tokens for all of this exist and are `--color-muted`, `--color-text`,
`--color-primary`, `--color-warning`, `--color-success`, `--color-danger`,
`--color-edge*`. There is also a `.text-muted` utility class, which the branch
uses correctly at 21 sites — beside the 60 broken ones.

### F4 — A parallel type and geometry scale

| Branch                                 | Count | System                            |
| -------------------------------------- | ----- | --------------------------------- |
| `font-size: 0.<n>rem` (0.6 – 0.9)      | 104   | 10 / 11.5 / 13 / 13.5 / 15 / 16 / 17px |
| `gap: 0.<n>rem` (0.15 – 1.25)          | 111   | Tailwind spacing scale            |
| `border-radius: 3\|4\|6px`             | 39    | `--radius-control` 8, `-inner` 7, `-bare` 6, `--radius-surface` 16, `-slim` 12 |
| `border-radius: 8\|12\|16px`           | **0** | —                                 |

Not one radius in the feature lands on the system's scale, and the type scale is
rem-based against a px-based system. `text-transform: uppercase` appears at 29
sites in 22 files, each with its own `letter-spacing` (0.04 – 0.08em) and
`font-weight` — reinventing `metrics-card__row__label` (Orbitron, 10px, 0.16em)
22 times, in the wrong font.

### F5 — Three status vocabularies, none of them the app's

The feature ships three unrelated status displays:

1. `EventStatusBadge` — 7 lifecycle statuses × 2 variants (`inline`, `corner`),
   as a bespoke uppercase pill with 6 hardcoded fills. The `corner` variant is
   `position: absolute; top: 120px`, a magic number tied to a cover-image height
   set in a different file.
2. Signup status — raw i18n text plus a `fa-light` icon, at `0.72rem`.
3. Vehicle fit / mismatch — a check or triangle icon, coloured from the
   undeclared tokens of F3.

Meanwhile `.label` has been retired, `Chip` now owns interactive pills (with
icon-**and**-colour state signalling and an `sr-only` state name), and `Panel`'s
`tone` puts non-interactive status on the end-cap — *"the cap carries the tone;
the frame stays neutral"*. None of the three uses any of it.

### F6 — Every mode switch is built as a row of independent actions

Five switches in the feature are plain `BtnGroup`s driving `:active`:

| Switch                          | Where                    |
| ------------------------------- | ------------------------ |
| list / calendar                 | `events/index.vue`       |
| upcoming / past / archived      | `events/index.vue`       |
| month / week                    | `CalendarGrid`           |
| confirmed / tentative / interested | `EventSignupCta`      |
| list / calendar (missions)      | `missions/index.vue`     |

`BtnGroup` gained `segmented` for exactly this: *"a switch rather than a row of
actions: the track recesses, one thumb slides to the chosen segment, and members
take radio semantics."* The signup CTA is the worst of the five — it renders one
solid button and two `variant="link"` buttons, which tells the user "Confirmed is
the primary action and the other two are afterthoughts" about what is in fact a
single three-valued choice.

`events/index.vue` also carries `.events-toolbar :deep(> *) { margin-right: 0 }`
— margin-fighting that deletes with F1.

### F7 — `PanelBody no-padding` is gone, and the calendar depends on it

`CalendarGrid` renders `<PanelBody no-padding rounded="all">`. The new
`PanelBody` declares exactly one prop, `rounded`; the panel plan removed
`no-padding` (and `no-min-height`, which never worked). So the calendar, drawn
edge-to-edge inside its panel, gains `4px 18px 18px` of padding it was never
laid out for.

Beyond that it overrides ~25 `.ec-*` library selectors with remixed literals
(`rgba(#c8c8c8, .22)` borders, `rgba(#000, .18)` day fills, a 999px primary
today-pill), when the library's own CSS custom properties are the seam and the
app now has tokens to feed them.

### F8 — Eight category colours, five of which are already tokens

`CalendarGrid`'s `categoryStyles` map:

| Category           | Hex       | Token                        |
| ------------------ | --------- | ---------------------------- |
| `other`            | `#7a8288` | `--color-gray-light` / `--color-endcap` |
| `ship_combat`      | `#dc3545` | `--color-danger`             |
| `ground_combat`    | `#fa6800` | `--color-warning`            |
| `cargo_hauling`    | `#428bca` | `--color-primary`            |
| `mining`           | `#d4af37` | `--color-gold`               |
| `combined_combat`  | `#c0392b` | — invented                   |
| `salvage`          | `#16a085` | — invented                   |
| `exploration`      | `#9b59b6` | — invented                   |

Data-driven colour, declared inline in one component, needed by at least three
(calendar chip, event panel, mission category filter). Five of the eight
duplicate a token and would drift from it silently.

### F9 — Almost no test hooks

4 `data-test` and 6 `aria-label` across 66 files. For comparison, `Btn` alone has
91 `data-test` and 55 `aria-label` call sites app-wide, and the button plan
called zero test coupling *"the single biggest de-risking fact in the
migration"*. Here the absence is the opposite: there is no net under a
41k-addition feature, and the visual-tests rig (#4339) it could hang off did not
exist when the branch was written.

Untranslated literals in the same class: `title="Drag"` (`EventTeamCard`,
`EventShipCard`), matching the label plan's F6 hardcoded `"Classifications"`.

## Decisions

### D1 — One status carrier per role, no overlap

`EventStatusBadge` is deleted. Its three jobs split by scope:

| What                                | Carrier                | Why |
| ----------------------------------- | ---------------------- | --- |
| Event lifecycle (draft…cancelled)   | `Panel` `tone`, on the cap | Per-*surface* status. The redesign made the cap the app's status signature. Kills the `top: 120px` corner badge outright. |
| Signup status (confirmed/tentative/interested/withdrawn) | `Chip` | Per-*person*, inline, in a row of peers — a chip's exact shape, and it brings icon+colour signalling and an `sr-only` state name. |
| Vehicle fit / mismatch              | icon, on `--color-success` / `--color-warning` | A boolean qualifier on one field, not a status. Already icon+colour. |

Lifecycle → tone mapping: `draft` neutral, `open` success, `locked` highlight,
`active` primary, `completed`/`past` neutral, `cancelled` error.

`animated` stays **off**. A grid of pulsing caps is noise, and the prop exists
for a single validation surface, not a list.

### D2 — Cover images via `--panel-image-height`, not `:deep()`

All 18 deep selectors from F2 delete. Each card becomes:

```vue
<Panel :bg-image="cover" bg-rounded="top" style="--panel-image-height: 200px">
  <PanelHeading shadow="top" :level="HeadingLevelEnum.H2">…</PanelHeading>
```

`EventShipCard`'s `$panelInnerBorderRadius` becomes `--radius-surface-inner`.

### D3 — The event card's stat list becomes `metrics-card__rows`

The five icon+text lines (date, recurrence, location, meetup, signups) are a
label/value list, which the system already has as a content primitive in
`shared/components/metricsCard.scss`: Orbitron 10px tracked label, tabular
right-aligned value, `edge-faint` hairline between rows, none after the last.
Those classes live in the **consumer's** scope by design (Vue keeps slotted
markup in the parent's), so a card uses them directly — no new primitive, and
the icons go, because the label already says what the value is.

Five rows in a narrow grid column pair two-per-line under `--split`.

### D4 — Slot rows are list rows at `xs`, not nested cards

`EventSlotRow` stops being a `rgba(255,255,255,.03)` r4 box. A stack of six slots
is a list; the system's row primitive gives it one hairline per row and no frame,
which is the "one box" principle both prior redesigns are built on.

Row-level controls drop to `size="xs"` — the size the button redesign added
precisely so *"a control that sits in a chip row lines up with the chips beside
it instead of towering 14px over them."* This is where F1's mechanical
`small → omit` mapping is deliberately **not** mechanical: at slot density the
answer is `xs`, not the new `sm` default.

The "you are here" 999px teal pill becomes `Chip state="included"`. The
`1px dashed` divider under the expand form becomes solid `--color-edge-soft` —
dashed borders appear nowhere else in the app.

"Mine" state: the retired pattern is a recoloured border. The system's existing
mark for *this is the one* is `metrics-card__tile--primary`'s 3px left rail
(a `$primary` → `rgba($primary, .15)` gradient), and its mark for *engaged* is
`.btn--grouped.active`'s inset rule. Take the rail — it reads at row scale and it
is already in the codebase.

### D5 — Five switches become `segmented` groups

Every switch in F6 gets `<BtnGroup segmented>`. For the signup CTA this is a
semantic fix, not a visual one: three peer options stop being styled as one
action plus two links, and gain `role="radiogroup"` / `aria-checked`. Withdraw
stays outside the group as `variant="bare" tone="danger"`.

`.events-toolbar :deep(> *)` deletes.

### D6 — The signup CTA and team box become real panels

Both are hand-rolled boxes today (`rgba(255,255,255,.03)` r6 /
`rgba(0,0,0,.45)` r6). Both are titled sub-surfaces inside a page, which is
`Panel variant="slim"` + `PanelHeading tone="metric" compact divider` — the
`divider` prop exists so *"a slim panel's head still reads as a head without the
full frame's weight behind it."*

`EventTeamCard`'s three bare `<button>` elements (close, edit, drag) become
`Btn size="xs" variant="bare"`, the delete taking `tone="danger"` so it inherits
the system's danger hover instead of `var(--danger, #c66)`. The `⋮⋮` text handle
becomes `fa-grip-vertical` with a translated `aria-label`, replacing
`title="Drag"`.

### D7 — Calendar: drive the library through its own custom properties, fed from tokens

`PanelBody` goes; the calendar sits in `Panel`'s default slot, so no padding
applies and F7's regression cannot happen. The toolbar becomes
`PanelHeading tone="metric" divider` with the month title, its `#actions` slot
carrying a plain `BtnGroup` (prev/next/today — actions) and a
`BtnGroup segmented` (month/week — a switch).

The ~25 `.ec-*` override rules collapse to variable assignments:

```css
--ec-bg-color: var(--color-surface);
--ec-border-color: var(--color-edge-soft);
--ec-text-color: var(--color-text);
--ec-today-bg-color: rgb(66 139 202 / 0.26);   /* .btn--grouped.active */
--ec-highlight-color: rgb(66 139 202 / 0.22);  /* .chip--included */
```

The alphas are the system's documented ones rather than newly mixed.

The month chip is a chip in all but name — dot, label, tint, left rail. Render
`Chip bare` inside the library's event slot, with `dot` carrying the category
colour: `bare` exists for *"a chip's contents inside a control that is already
interactive"*, and the library's event element **is** the click target. That
deletes `.fy-event-chip--compact` entirely. The week-view cover chip stays
bespoke — a background-image card is not a chip.

### D8 — Category colours become declared tokens

Add `--color-category-*` to `@theme` in `entrypoints/tailwind.css`, aliasing the
five tokens F8 identifies and declaring the three new hues there rather than in a
component. Consumed by the calendar chip, the event panel and the mission
category filter alike.

### D9 — Type, spacing and radius come from the scale

The 104 rem font sizes, 111 rem gaps and 39 off-scale radii resolve to the token
scale. The 29 hand-rolled uppercase treatments resolve to
`metrics-card__row__label` / `__section-label` (Orbitron, 10px, 0.16–0.18em) or
`PanelHeading tone="metric"`.

Consequence worth stating: the 45 `<style lang="scss" scoped>` blocks mostly
shrink to nothing. The ones that survive must move to plain `<style scoped>` with
`@reference` if they want `@apply` — the button plan's D3, verified: under
`lang="scss"` those at-rules reach the minifier unrecognised and are **silently
dropped**.

### D10 — Test hooks and the visual-tests rig land with the feature, not after

F9's 4 `data-test` hooks are not a migration problem, they are a gap. Add:

- `data-test` on every interactive element the E2E suite needs to reach, matching
  the app's existing convention.
- A `visual-tests/events.vue` page covering the reconcepted surfaces — event
  card at each lifecycle tone, slot row in each state, signup CTA, team and ship
  cards, calendar month and week chips — and a Playwright snapshot spec, the same
  regression net the button and panel redesigns built for themselves in Phase 0.

## Phases

Ordering note: this plan is a **design** reconcept. The branch is 282 commits
behind and conflicting, so the merge is a prerequisite for everything and is
sequenced first, deliberately separate from any visual work — the two must not be
resolved in one pass.

### Phase 0 — Land the branch on `main` — **DONE**

1. Merge `origin/main` into `feat/mission-builder-v3`, resolving conflicts for
   correctness only, with **no** visual changes. Build must pass; the feature is
   expected to look wrong at this point.
2. Fix the TypeScript failures from F1's dead enum members (96 sites) — the
   compiler is the worklist.
3. Verify F2 and F7 in the browser: the collapsed cover-image cards and the
   padded calendar are the two regressions that prove the merge is honest.

Outcome — 21 conflicts, and four things worth carrying forward:

- **Credentials — resolved.** `config/credentials/{production,staging}.yml.enc`
  took main's side, because `97388e22a` rotated the Hetzner S3 keys and the
  branch's copy holds the revoked ones. The Discord bot entries the branch
  carried were then re-added on top of that version with
  `rails credentials:edit`, so both files are new blobs rather than either
  parent's — the rotated S3 keys and the Patreon credentials survive alongside
  the Discord ones. The superseded blobs remain at `020fa47a0` if anything needs
  recovering.
- **`transformErrors` is gone.** `0df682d2f` replaced it with
  `validationErrorFrom` / `standardErrorFrom` in `shared/utils/ApiErrors.ts`,
  which narrow with `isAxiosError` instead of casting. The two form shells were
  the only consumers left and now read `{ message, formErrors }`.
- **`Notifications::Discord` shadows `::Discord`.** The branch's new namespace
  means any `Discord::X` reference lexically inside `module Notifications`
  resolves to the wrong constant. Two sibling jobs already used the `::Discord::`
  root prefix for this reason; `new_patron_job` and its test did not, and broke.
  Any new notification code in that namespace needs the prefix.
- **`mission_builder` was never in the registry.** `a5f7e2347` made
  `config/feature_flags.yml` the source of truth, so the branch's
  `Flipper.add` data migration created a flag the next `bin/feature-flags sync`
  would prune. Declared now, with the three frontend call sites moved off the
  string literal onto `FeatureFlagName.MISSION_BUILDER`.

Local prerequisites for a green suite, both of which CI supplies and a fresh
worktree does not (`bin/setup` writes them; `supacode repo worktree-new` does not):

- `SHORT_DOMAIN` must be set **before Rails boots** — `config/routes.rb` gates
  `draw :short_routes` on it, so without it `/c/:short_code` falls through to the
  frontend wildcard and `Short::ModelCompareShareTest` sees 200 instead of 302.
- `bin/build-email-assets` must have run, and `.env.test.local` must carry
  `DB_PORT` + `WORKTREE_SUFFIX` (dotenv skips `.env.local` in test, so without it
  the suite runs against the shared `fleetyards_test`).

### Phase 1 — Tokens and primitives — **DONE**

4. `--color-category-*` (D8).
5. Delete `EventStatusBadge`; wire `Panel` `tone` and `Chip` per D1.
6. Sweep F3's undeclared properties to real tokens — 122 occurrences across 28
   files, mechanical, and it is what makes the muted hierarchy render at all.

Two things the doing changed:

- **The category tokens are declared outside `@theme`, not in it.** Tailwind
  drops a theme variable it cannot see used, and a category colour is only ever
  read through a style binding, which its scanner does not count as a use — so
  in `@theme` all eight would have been pruned and every chip would have fallen
  back to nothing. Confirmed against the built CSS, where `--color-lifted` is
  already absent from `:root` for exactly this reason. Same call the `--cap-*`
  geometry makes, one block down.
- **The token references carry explicit fallbacks** (`var(--color-muted,
  #7a8288)`) for the same reason, matching what `Panel`, `Btn` and `Chip` do in
  their own CSS. A bare `var()` in a scoped SCSS block would have re-created the
  bug the sweep was fixing.

`EventStatusBadge`'s `past` handling was worth keeping, so it became
`useEventStatus`, which returns the tone and the label key together — the two
cannot disagree about what a past-but-still-open event is.

### Phase 2 — Surfaces — **DONE**

7. Event card: `--panel-image-height` + `PanelHeading shadow="top"` (D2), stat
   list to `metrics-card__rows` (D3).
8. Ship card and mission panel: same treatment; `$panelInnerBorderRadius` →
   `--radius-surface-inner`.
9. Signup CTA and team card → `Panel variant="slim"` + metric heading (D6).
10. Slot rows → list rows at `xs`, `Chip` for own-signup, left rail for mine (D4).

The structural fact that made D2 straightforward: `Panel` parents the background
image to `.panel__inner`, so it covers the **default slot and stops there**. The
heading goes in the default slot — on the cover — and everything else moves to
`#footer`, below it. That is the API the hand-rolled absolute positioning was
imitating, and it is why the two detail heroes did not need their `bg-overlay`
scrim back: eight lines of metadata were never going to sit on a photo.

All 18 `:deep(.panel*)` selectors are gone. A nineteenth turned up on the way
out — `.spawned-events__item :deep(.panel-wrapper--outer-spacing)` in
`missions/[mission].vue`, targeting one of the three boxes the redesign
collapsed, so that margin reset had silently stopped applying.

**Deviation from D5, deliberate.** The signup CTA uses a plain `BtnGroup`, not
`segmented`. D5's goal was that the three options stop being styled as one action
plus two links, and a plain group achieves that. But these buttons *submit*, and
the CTA only renders when the viewer has no signup, so nothing is selected:
`role="radio"` with `aria-checked` would claim a selection that does not exist.
Grouped actions, not a switch. The other four switches are untouched and stay
`segmented` per D5.

Not done here, and the reason: `Fleets/Missions/TeamCard` is the near-duplicate
of `EventTeamCard` and has not had the D6 pass. That is Q5 — the mission side as
a sibling — rather than an oversight.

### Phase 3 — Controls

11. Five switches → `BtnGroup segmented` (D5).
12. Strip `inline` (124), map sizes and variants (F1), delete the margin-fighting
    in `events-toolbar`.
13. Bare `<button>` elements in `EventTeamCard` / `EventShipCard` → `Btn` (D6).

### Phase 4 — Calendar

14. Drop `PanelBody`; toolbar into `PanelHeading tone="metric" divider` (D7).
15. `.ec-*` overrides → custom-property assignments from tokens.
16. Month chip → `Chip bare`; delete `.fy-event-chip--compact`.

### Phase 5 — Scale cleanup and verification

17. D9's type / spacing / radius sweep; `lang="scss"` → plain `<style scoped>`
    where `@apply` is wanted.
18. `visual-tests/events.vue` + Playwright snapshots; `data-test` hooks (D10).
19. `pnpm test`, `pnpm test:e2e:run`, `prettier`, `eslint`, `knip`.

## Open questions

- **Q1 — Does the event grid want `default` or `slim` panels?** The panel plan
  puts `slim` on *"repeated cards in narrow columns, where the full frame reads
  as noise"*, which describes a three-up event grid. But `slim` has no end-caps,
  so D1's cap-carried lifecycle tone falls back to the edge — the one place Panel
  documents a tone reading two ways. Recommendation: `default`, because an event
  card is a hero card with a cover image rather than a dense stat tile, and the
  tone is load-bearing here. Wants a look on the visual-tests page.
- **Q2 — Should the three invented category hues (D8) be replaced rather than
  declared?** `#c0392b` sits very close to `--color-danger` `#dc3545`, and
  `combined_combat` beside `ship_combat` is exactly where they appear together.
  Distinguishability across the eight-colour set has not been checked.
- **Q3 — Does the week-view cover chip survive at all?** A background-image
  event card in a one-hour slot is ~56px tall with an `inset 0 0 0 1000px rgba(0
  0 0 / .45)` scrim over it. The month chip's icon+tint treatment may simply be
  the better one in both views.
- **Q4 — Is `Chip` the right carrier for four signup statuses?** `ChipStatesEnum`
  is three-valued (neutral / included / excluded) and deliberately so. Four
  statuses either need a fourth state on the shared primitive — which the label
  plan resisted — or must map two of them onto `neutral` and lean on the label.
- **Q5 — Does the mission side get the same pass in this plan or a sibling?**
  `Fleets/Missions` (9 components) is a near-duplicate of `Fleets/Events` by
  construction; the findings apply unchanged, but pairing them doubles a phase
  that is already large.

## Design review

Interactive reconcept of the surfaces, in the new language, with the branch's
current render beside each:

<https://claude.ai/code/artifact/e4e2cd78-99e4-4c12-b01f-bf276e633a38>
