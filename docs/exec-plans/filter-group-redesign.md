# FilterGroup redesign

## Goal

Rebuild `base/FilterGroup` on the control language `btn-redesign` (#4338)
established and the surface language `panel-redesign` (#4362) established, and
give it the combobox semantics it has never had — without changing its public
API.

Issue: #4371.

## Context

`FilterGroup` is the app's select: **135 `<FilterGroup>` tags across 68 files**.
It sits directly beside redesigned buttons in every filter bar, and its trigger,
its popover and its rows each disagree with them in a different way.

It predates both redesigns. Unlike `Btn`, it was never rebuilt — it was styled
once from the Bootstrap 3 base and has been extended since.

## Findings that drive the design

### F1 — The API survives, so this is a five-file change, not a codemod

Scanning all 135 tags for the props they actually pass:

| Prop                       | Tags |
| -------------------------- | ---- |
| `name`                     | 134  |
| `v-model`                  | 132  |
| `label`                    | 116  |
| `options`                  | 96   |
| `searchable`               | 67   |
| `nullable`                 | 50   |
| `multiple`                 | 43   |
| `no-label`                 | 41   |
| `query-fn`                 | 38   |
| `query-response-formatter` | 24   |
| `paginated`                | 21   |
| `translation-key`          | 19   |
| `inline`                   | 9    |
| `search-label`             | 6    |
| `disabled`                 | 3    |
| `size`                     | 2    |
| `hide-selected`            | 1    |
| `big-icon`                 | 1    |

This is the single most important fact about the work: every one of these keeps
working unchanged, so the rebuild touches `FilterGroup/index.vue`, `index.scss`,
`Option/index.vue`, `Option/index.scss` and `types.ts` — and no call site.

`btn-redesign` needed a 468-site codemod. This needs none.

### F2 — Three props are dead at every call site

`query` (the `UseQueryReturnType` variant, distinct from `queryFn`), `error`,
and `hideLabelOnEmpty` are passed by **zero** of the 135 tags. `hideLabelOnEmpty`
looks used only because `FormInput` has a prop of the same name, which the login,
signup and password pages do use.

`error` is worth a second look rather than a straight delete: it is the only
validation affordance the component has, and a select that cannot show an error
is a gap, not a saving. The other two are dead weight.

### F3 — Nothing in the component is a control

- The trigger is a `div` with `@click` (`index.vue:465-482`).
- Each option is an `<a>` with no `href` and `@click` (`Option/index.vue:36-56`).
- No `tabindex`, no `combobox`/`listbox`/`option` roles, no `aria-expanded`,
  no `aria-activedescendant`.
- No arrow-key navigation, no Home/End, no type-ahead, no Escape.
- When the group is not `searchable` — **68 of the 135 tags** — the label's
  `for` points at the collapsed container's id (`index.vue:231-237`), which is
  a `div`. Clicking the label does nothing and screen readers announce nothing.

The component is completely keyboard-inoperable. That is the substance of the
redesign; the styling is the visible half.

### F4 — Closing is document-click only

`documentClick` is bound on `document` at mount (`index.vue:298-309`). There is
no Escape handler and no focus-out handling, so a keyboard user who could reach
the popover would have no way out of it.

### F5 — The imperative API is real and must survive

`defineExpose({ reset, clear, clearSearch })` is called through template refs at
four places:

- `frontend/components/base/ModelFilterGroup/index.vue:93,97,103`
- `admin/components/base/ModelFilterGroup/index.vue:104,108,114`
- `frontend/components/Compare/Models/Form/index.vue:49`
- `frontend/pages/tools/cargo-grids.vue:259,264`

A rebuild that quietly drops these breaks the compare tool and both model
pickers, and TypeScript will not catch it — the calls are all `?.`-guarded.

### F6 — The trigger borrows the form-input treatment

`index.scss:33-48` — `rgba($input-bg, 0.9)` inside a `1px solid $input-border`
edge that is _darker_ than its own fill, at `$border-radius-base` (4px) against
`--radius-control`'s 8px, with no end-caps. The redesign's controls are a dark
fill inside a _lighter_ edge. Hover is a hand-picked `color: white; background:
$input-bg` rather than `--color-control-hover`.

This is the same inverted fill/edge relationship the forms issue (#4372)
describes, inherited through `$input-bg` / `$input-border`.

### F7 — The popover is a second dropdown menu

`btn-redesign` ships `BtnDropdown/Menu`: `bg-gray-darker`, `border-edge`,
`rounded-control`, `role="menu"`, its own end-caps and an `--color-edge-soft`
separator, at `z-index: 2100`. It also documents _why_ it is opaque where a
button is translucent — a popover floats over arbitrary content, so anything
showing through competes with its labels.

`FilterGroup`'s popover (`index.scss:96-115`) is the same object built from
different values: `rgba($gray-darker, 0.95)`, `1px solid $input-border`,
`border-top: none`, and a `0 1px 3px rgba(black, 0.9)` shadow on the wrapper.

After #4338 the two are open on the same screen — the ships filter bar.

### F8 — The glow rail, and a keyframe that should die with it

`Option/index.scss:62-86` carries the table row rail byte-for-byte, on every
option row on hover. PR #4595 removed that rail from the table and introduced
`--cap-h-row` / `--cap-r-row` for it, so the replacement already exists.

`Option/index.scss:88-97` animates `.active` with `animation-name: flash`, and
the last surviving `@keyframes flash` in the frontend is declared at the bottom
of that same scoped block (`:110`). It resolves only because the reference and
the declaration share a scope. It should go with the rail, not be preserved.

Each row also carries `border-bottom: 1px solid $input-border` where internal
divisions in the new language are `--color-edge-soft`, and a `transition: all
0.5s ease` on its icon.

`RadioList` aside, this is the last of the three glow copies `btn-redesign`
set out to remove. Two more live in `TabNavView` and the `flex-list` partial —
tracked separately in #4596.

### F9 — Behaviour that must not regress

The component does more than it looks like it does, and none of it is covered
by a test:

- `fetchMissingOption` — a value selected but absent from the loaded page is
  fetched on its own so the trigger can show its label rather than a raw id.
- Search is debounced at 500ms and resets pagination to page 1.
- `paginated` tracks `currentPage < totalPages` off the response meta and
  renders a fetch-more button inside the popover.
- Options are sorted client-side, alphabetically by label — **except they are
  not**, see F12.
- `keepPreviousData` keeps the list stable while refetching.
- With `multiple` and not `hideSelected`, the selected rows render in a second
  `Collapsed` _outside_ the popover while it is closed.

### F10 — The chevron and the remove affordance are rotated glyphs

The chevron is `fa-chevron-right` rotated 90° (`index.scss:70-75`); the per-row
remove control is a `fa-plus` rotated 45° into an × (`Option/index.scss:93-96`).
Both should become the glyph they are trying to be.

### F11 — Test coupling is not zero

`btn-redesign` could rebuild freely because nothing asserted on the button's
DOM. That is not the case here.

`test/playwright/e2e/CargoGrids.spec.ts:34,125` drives the component through
its internals:

```ts
await filterGroup.getByTestId("filter-group-title").click();
await filterGroup.locator("input").first().fill("Caterpillar");
```

Two constraints follow. `data-test="filter-group-title"` has to survive onto
the new trigger even though the element under it changes from `div` to
`button`. And the search input has to stay the first `input` in the subtree —
which the popover rebuild could easily break by adding a hidden input, a
listbox filter or a native control for the combobox.

It is also the only automated coverage the component has anywhere: there is no
unit spec, no colocated test, and nothing else asserts on a `filter-group` id.

### F12 — The sort never reaches the list — found in Phase 0

`sort()` exists and `availableOptions` applies it, but the popover renders
`filteredOptions` (`index.vue:266-276`), which returns `internalOptions`
untouched.

The consequence is split: `selectedOptions` derives from `availableOptions`, so
the **selected** rows come out alphabetical, while the **options** a user picks
from are in whatever order the API returned them. Two lists in the same popover,
ordered differently, from one sort function that only half-runs.

The rebuild should sort the rendered list. The Phase 0 spec pins the current
behaviour with that noted, so flipping the assertion is a deliberate act rather
than a surprise.

Found by writing the Phase 0 tests, which is the argument for the gate.

### F13 — The popover is attached, and the shared surface would detach it

Not drift, and not obviously wrong: FilterGroup's popover is drawn as a
continuation of its trigger. `.filter-group-items` carries `border-top: none`
and only bottom radii, and the trigger's `.active` and `.selected` states drop
their own bottom radii to meet it (`index.scss:69-72`, `:88-95`). The two read
as one object.

`BtnDropdown/Menu` is the opposite: a detached surface floating over the page,
fully bordered, `rounded-control` all round, with end-caps top and bottom.

Moving FilterGroup onto that surface is therefore not a like-for-like swap —
it changes what the control _is_ on screen. It also strands the search box,
which today sits **outside** the bordered area as a sibling of
`.filter-group-items`, above it.

This is a design decision, not a refactor, and it belongs to whoever owns the
look rather than to the phase that happens to touch the CSS.

## Decisions

### D1 — A custom combobox, not a native `<select>`

Native `<select>` cannot express per-option icons, the multi-select chip
behaviour, in-popover search, async pagination, or the fetch-more row. The
feature set decides this; there is no trade to weigh.

The consequence is that the ARIA has to be written by hand and is the risk
surface of this work, not the CSS.

### D2 — The trigger becomes a real `<button>`

`role="combobox"`, `aria-expanded`, `aria-controls`, `aria-haspopup="listbox"`.
This also fixes F3's label problem for the 68 non-searchable tags: `for` points
at the button, and clicking the label opens the group.

When `searchable`, the search input keeps the `for` — the pattern stays as it
is today, only with a real control on the other end of it.

### D3 — The popover reuses `BtnDropdown/Menu` through a shared descendant

Not `BtnDropdown/Menu` directly: it hard-codes `role="menu"` and provides
`BTN_CONTAINER` to style its children as menu buttons, and a listbox of options
is neither. The shared part is the _surface_ — opaque `bg-gray-darker`,
`border-edge`, `rounded-control`, end-caps, `z-index: 2100`.

Extract that surface into a primitive both compose, so the two popovers cannot
drift again. This is the one piece of the work that reaches outside FilterGroup.

### D4 — Keep the props API frozen; drop only `query` and `hideLabelOnEmpty` — **DECIDED**

Both are dead at all 135 tags and neither has a story.

`error` **stays**, carrying today's tooltip behaviour unchanged. It is unused,
but it is the only validation affordance a select has, and #4372 has to set an
error pattern for every form control anyway. Building one here first would mean
#4372 either follows a pattern set by the odd control out, or overrides it.
FilterGroup inherits instead.

`bigIcon`, `hideSelected` and `size` stay despite one or two uses each — they
carry behaviour, and removing them means changing call sites, which is exactly
what this redesign is trying not to do.

### D5 — Type-ahead is in scope — **DECIDED**

Typing on a closed or open group jumps to the first option whose label starts
with what was typed, with the usual buffer-and-timeout behaviour.

68 of the 135 tags are not `searchable`, and several of those lists run past 50
entries — manufacturers, star systems, model classifications. Without
type-ahead the only way through them is fifty arrow presses. A native `<select>`
does this for free, which is exactly the expectation D1 opts out of and has to
pay back by hand.

### D6 — One PR

The component is five files and no call site changes. Splitting the visual half
from the semantic half would be artificial: the trigger changing from `div` to
`button` is simultaneously both, and the two halves would conflict in the same
lines.

Worth noting against #4362's experience: that PR was bounced twice by the review
bot's file limit at 118 files. This one is nowhere near that.

## Prop API: before → after

| Prop               | Before                 | After                              |
| ------------------ | ---------------------- | ---------------------------------- |
| `query`            | `UseQueryReturnType`   | **removed** — 0 uses               |
| `hideLabelOnEmpty` | `boolean`              | **removed** — 0 uses               |
| `error`            | `string`, tooltip-only | kept, given a real error treatment |
| everything else    | —                      | unchanged                          |

## Phases

### Phase 0 — Cover the behaviour before touching it

F9 lists six behaviours with no test. Land tests against the _current_
component first, so the rebuild has something to fail against. The visual-tests
page (`pages/visual-tests/forms`) already exists as the render surface.

This is the gate: no rebuild before the async behaviour is pinned.

### Phase 1 — Semantics and keyboard

Trigger to `<button>` with combobox roles; options to real `option` roles;
arrow keys, Home/End, Enter/Space, Escape, focus-out, type-ahead (D5);
`aria-activedescendant`.
No visual change in this phase beyond what the element swap forces.

### Phase 2 — Move the component off SCSS

**Corrected after Phase 1; the original split of this phase from the next one
was wrong.** See F13.

`btn-redesign`'s D3 verified empirically that `@reference` and `@apply` inside
`<style lang="scss">` pass through sass untouched, reach the minifier as
unknown at-rules and are **silently dropped**. `BtnDropdown/Menu`'s surface is
authored with `@apply`, and FilterGroup is SCSS, so the surface cannot be
shared until the component moves to a plain `<style scoped>` block with
`@reference`.

That migration also has to replace every injected SCSS variable the component
reads — `$input-bg`, `$input-border`, `$primary`, `$gray-darker`,
`$border-radius-base`, `$input-color` — with theme tokens, which is the same
work the restyle was going to do. So the two are one phase, not two.

The failure mode is silent, which is the reason to write this down: a popover
that lost its styling renders as unstyled content over the page rather than as
an error.

### Phase 3 — The shared surface, the trigger and the rows

Extract the surface primitive from `BtnDropdown/Menu` (D3) and move both onto
it; trigger onto `--color-control` / `--color-edge` / `--radius-control` with
end-caps; rows onto `--color-edge-soft` divisions; drop the glow rail and the
`flash` keyframe (F8); real chevron and × glyphs (F10).

### Phase 4 — Verify

Visual-tests page across all prop combinations; keyboard walkthrough; the four
imperative call sites from F5 exercised by hand.

## Open questions

1. **`size`** — `types.ts` documents the separate per-control enum as
   deliberate: `MEDIUM` is already 48px, matching `Btn`'s `md` and
   `FormInput`'s `medium`, and each control keeps its own copy so one can gain
   a size without dragging the others in. There is no drift to fix, so the
   default is to leave it alone. Merging the three enums into one scale is a
   separate change that reaches `FormInput` and reverses a documented decision.
