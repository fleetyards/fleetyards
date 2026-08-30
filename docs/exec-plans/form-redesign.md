# Form control redesign

## Goal

Give every form control the language `btn-redesign` (#4338) and
`panel-redesign` (#4362) established, and fix what that surfaces on the way.

Issue: #4372. The language in this plan was **built and judged on the
visual-tests page before being written down** — the decisions below are what
survived looking at them, and several of them are not what the same reasoning
produced on paper.

## Context

The forms are the largest untouched surface in the app:

| Component                                                                   | Tags | Files |
| --------------------------------------------------------------------------- | ---: | ----: |
| `FormInput`                                                                 |  374 |   104 |
| `FilterGroup`                                                               |  126 |    66 |
| `FormToggle`                                                                |   71 |    39 |
| `FormFileInput`                                                             |   53 |    28 |
| `FormTextarea`                                                              |   44 |    38 |
| `FormActions`                                                               |   37 |    37 |
| `FormCheckbox`                                                              |   28 |    21 |
| `RadioList`                                                                 |   28 |    13 |
| `FormDatePicker` / `DateTime` / `Tabs` / `InputGroup` / `Toggle` / `Slider` |   25 |     — |

## Findings that drive the design

### F1 — One variable pair is the whole vocabulary

`$input-bg` and `$input-border` are read by ten component stylesheets and by
`stylesheets/frontend/partials/v-select-overrides.scss`. Change the pair and
every control changes at once — which is why `FilterGroup`'s trigger could not
be fixed on its own, and why a **third-party dropdown** moves with them whether
that is intended or not.

### F2 — The relationship is inverted, not merely different

```
Input today:  fill $gray-dark  #3a3f44  inside border $gray-darker #272b30   ← light in dark
Control:      fill --color-control #272b30/.9 inside --color-edge #7a8288/.5 ← dark in light
```

Plus 4px against `--radius-control`'s 8px, an inset well shadow, and no caps.

### F3 — Focus is invisible on every input in the app

`outline: none` with nothing put in its place, at **374 call sites**, both
password fields and the login form included.

### F4 — Radios cannot be reached by keyboard at all

`RadioList` hides its input with `display: none`, which removes it from the tab
order — which is why the `:focus` rule three lines below it has never once
fired. `FormCheckbox` uses `opacity: 0` and absolute positioning for the same
job. The two components simply disagree; the fix is one line.

### F5 — Every component answers `:focus`, so focus styling outlives focus

A pointer click leaves a control focused, so their rules keep firing when
nothing looks focused any more. This produced two separate bug reports while
building the preview: a primary edge that stayed on the radio you had just
clicked, and an inset primary ring that stacked on the edge below and read as a
2px focus.

### F6 — State is drawn with whichever property was to hand

`border` here, `inset box-shadow` there, and on the radio the dot **itself** is
a shadow in the surrounding colour. Three collisions came out of this in one
afternoon. The rule that ends it is D4.

### F7 — A field's frame cannot live on the field

An `<input>` is a replaced element and renders no pseudo-elements, so a cap
cannot sit on it. The frame moves to `.base-input__wrapper` — which is the
better place regardless: it makes prefix, field and suffix **one control**
rather than three boxes pretending to be one.

### F8 — There is no error message treatment at all

A field puts the message in a tooltip — invisible until hover, worth nothing to
a screen reader. `FormCheckbox` and `FormToggle` render `{{ errorMessage }}` as
a **bare text node** after the label, with no element and nothing between them,
so it reads as "Accept termsThe terms field is required".

The colour is also on the wrong half: `--with-error label { color: $danger }`
turns the _label_ red and leaves the message default.

### F9 — `RadioList` has no error state

It never calls `useField`, so a form has no way to mark it invalid. `FilterGroup`
does not bind a field either.

### F10 — Two controls have no label

`FormInput`, `FormTextarea` and `RadioList` all have a block label above the
control. `FormCheckbox` and `FormToggle` are the only two without one, so their
inline text does both jobs — and in a mixed row they start at the top while a
field starts below its label.

### F11 — A translucent edge composites over whatever fills the box

`--color-edge` is 50% transparent and a background is painted **under** the
border by default. The radio's dot is made by filling the box primary and
punching a ring back out of it with an inset shadow — and an inset shadow stops
at the padding box. So the blue stayed under the border and read as a primary
edge on the chosen radio. `background-clip: padding-box` is the fix.

### F12 — `color-scheme` is dead, and deliberately left that way

`stylesheets/frontend/base.scss:1` reads `bas:root {`, so `color-scheme: light
dark` matches nothing. It looks like a typo, and it is **not** being fixed here:
switching `color-scheme` on changes how the browser renders native controls,
which is the worst possible side effect to take mid-redesign. Its own change,
with its own verification.

## Decisions

### D1 — One signature per control, carrying its state — **DECIDED**

|         | signature                                    |
| ------- | -------------------------------------------- |
| rest    | neutral                                      |
| invalid | `--color-danger`                             |
| focused | `--color-primary`, and it wins while focused |

Not invented: `Panel` already says "the cap carries the tone; the frame stays
neutral", and `Btn` rests its cap at `--color-endcap` and turns it primary on
hover, active and focus-visible.

### D2 — Which element is the signature is decided by the markup — **DECIDED**

The **cap** for fields, the **edge** for the boxes you tick. F7 forces it, and
it is worth stating rather than treating as an accident.

Tried and rejected: the edge for fields too. It was applied and reverted within
a minute of looking at it.

### D3 — Focus answers `:focus-visible` — **DECIDED**

Driven by F5. Every component's `:focus` rule becomes `:focus-visible`. Until
they are changed, the preview resets `:focus:not(:focus-visible)` back to rest.

### D4 — One property per meaning — **DECIDED**

The signature (cap or edge) carries focus and tone. The **content** — tick, dot,
flooded track — carries selection, and never the edge.

This is the rule that comes out of F6, and it was reached by getting it wrong
three times: filling a checkbox primary hid its tick, which is a primary SVG;
colouring the edge on selection made focus invisible on the one control a
keyboard lands on; and widening the edge to compensate was a workaround for a
collision that should not have existed.

### D5 — Hover lifts the fill — **DECIDED**

Onto `--color-control-hover`, which `Btn` already uses for this. **Not** on a
checked radio or toggle, whose fill _is_ the state.

### D6 — Disabled goes quiet, not neutral — **DECIDED**

The signature drops to `--color-edge-faint`, so a disabled control cannot be
read as a resting one.

### D7 — `FormCheckbox` and `FormToggle` gain a block label — **DECIDED**

From F10. Their inline text becomes what it already is — the option's text, not
the field's. The alignment then follows on its own, and the preview's
`.label-slot` scaffolding has nothing left to do.

### D8 — The error message is inline; the tooltip is an addition, never the message — **PROPOSED**

All six form components show errors through `v-tooltip` and nothing else. A
tooltip cannot be triggered by touch at all, so on a phone the message today is
simply invisible — and on a desktop a sighted user has to hover a field to find
out why the form refused them.

So the floor is not a presentation choice: **the message is always in the DOM
and always tied to its input with `aria-describedby`**, whatever is done with it
visually.

On top of that floor:

- **Inline, below the control, by default** — every viewport, every page.
- **The tooltip stays only where the layout genuinely cannot give the message a
  line**, and even there it repeats what is already in the DOM rather than being
  the only copy.

That is a step past "inline on mobile, tooltip on desktop login": the split by
viewport fixes the touch case and leaves the desktop one, where discovering an
error still requires hovering the field that caused it. `useMobile` exists if a
viewport split is wanted anyway.

Worth pricing before committing: an inline message changes a control's height
when it appears, so a form reflows as it validates. That is the reason to decide
it here rather than per-component.

## Phases

### Phase 0 — Build it and look at it — **DONE**

~200 lines of unscoped CSS in the visual-tests forms page, reaching nothing
else. Every decision above was made against it, and four were reversed by it.

### Phase 1 — Tokens, then the fields

`FormInput` and `FormTextarea` onto the language. The field height becomes a
token: the preview hard-codes `43px` to centre a control beside a field, and
that number quietly stops being right the moment anyone changes it.

### Phase 2 — The boxes you tick

`FormCheckbox`, `RadioList`, `FormToggle`. Carries F4 (one line), D3, D7, and
the `background-clip` from F11.

### Phase 3 — Error messages

The message gets a real element, a place in the layout and `aria-describedby`,
per D8 — which means touching all six components, since every one of them puts
the message in a tooltip and nowhere else. `RadioList` gets an error state at
all (F9).

This is the phase that is about accessibility rather than appearance, and it is
the one most likely to be cut for time — it should not be.

### Phase 4 — The rest of the surface

`FormFileInput` (53 tags, the largest uncovered), `FilterGroup`'s trigger — the
gap #4371 deliberately left — `FormDatePicker`, `Slider`, `Toggle`, and a
decision about `v-select-overrides.scss` (F1).

### Phase 5 — Verify

Keyboard walkthrough of every control; the error states page in both
treatments; and the 700-odd call sites spot-checked where they carry props the
visual-tests page does not.

## Open questions

1. **The vendor dropdown.** `v-select-overrides.scss` is coloured from the same
   pair. Does it follow the redesign, get pinned to the old values, or get
   replaced by `FilterGroup`?
2. **`RadioList`'s error state** needs it to bind a field, which is a change in
   what the component _is_, not how it looks.
3. **Field height as a token** — see phase 1. Worth deciding early, because
   every control that sits beside a field depends on it.
