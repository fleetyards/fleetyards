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

### F14 — Moving the frame grew every field by two pixels

The frame moved from the input to its wrapper (F7) and the `43px` stayed on the
input. With `box-sizing: border-box` that number had _included_ the border, so
the control's outside went from 43 to 45 — against a `Btn` sm built to match it
at 43, and against `FormInputGroup`, whose comment says exactly that.

It surfaced three times as a two-pixel gap and was answered three times as a
symptom: a `+ 2px` on the checkbox's alignment, another on the toggle's, and a
third noticed on the FilterGroup trigger before the cause was read.

The height tokens are outer heights now — the number a neighbour needs — and the
input reads `calc(var(--field-h) - 2px)`.

### F15 — Copied internals age silently

Three components carried a copy of `FormInput`'s field styling. `FormDatePicker`
said so in a comment — "match `.base-input__wrapper input` from FormInput
exactly" — and did, to a version that no longer existed. `FormFileInput` copied a
field it does not have: the only `<input>` in its template is `hidden`, so none of
it had ever drawn a pixel. `FormDateTime` implemented the same picker library a
second time and targeted `dp__` classes that release 14 does not emit, so its
whole stylesheet, palette included, matched nothing.

None of them failed. CSS that matches nothing is silent, and a copy is only
wrong once the original moves.

### F16 — A failed upload reached nobody

The uploader caught the error, cleared itself, raised a toast with whatever the
failure stringified to — "Error creating Blob" — and then let `.then()` run
anyway, so the only event a consumer received was `upload:done` carrying the list
`clear()` had just emptied. A consumer could not tell a successful upload of
nothing from a failed upload of something.

The same diagnosis as D8 one layer down: the error was in a bubble beside the
control instead of on it.

### F17 — An override for a component that is not installed

`v-select-overrides.scss` styled `.v-select` and friends. `vue-select` is not a
dependency and the class appears in no template; the file was compiled into every
frontend bundle regardless.

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

### D7 — `FormCheckbox` and `FormToggle` gain an alignment prop, not a label — **DECIDED, revised**

From F10. The first answer was that they gain the block label every other
control has, and that alignment would follow from it. Building it says
otherwise.

A block label over a checkbox is a duplicate: the text beside it already names
it, so a second label above would say the same thing twice for the sole purpose
of taking up room. `RadioList` is not the same case — there the block label
names the _group_ and the option texts name the choices, which are two different
things. A single checkbox has no such second level.

So it is `alignWithFields`, a boolean, off by default. It says what is actually
meant — line up with the fields beside you — rather than obtaining it by way of
an empty label.

Two details that only appeared once it existed. It has to reserve the label's
line **and** the field's height, with the control centred in the second:
reserving the line alone aligns the tops and leaves a 24px box at the top of a
43px band. And the height belongs on the control row, not on the component,
which since phase 3 holds two rows -- put it on the component and the error
message lands higher than the one in the field beside it.

### D8 — The message is inline everywhere; the tooltip survives only on the auth pages — **DECIDED**

All six form components show errors through `v-tooltip` and nothing else. A
tooltip cannot be triggered by touch at all, so on a phone the message today is
simply invisible — and on a desktop a sighted user has to hover a field to find
out why the form refused them.

**The floor, which is not a presentation choice:** the message is always in the
DOM and always tied to its input with `aria-describedby`.

**The default:** inline, below the control, on every viewport and every page.

**The exception:** the tooltip stays on login, signup, request-password and
change-password as a visual flourish, and nowhere else. Those four are the
`hideLabelOnEmpty` forms — the compact treatment where the label folds away, which
is why a tooltip was reached for there in the first place. Even on them it is an
addition that repeats what is already in the DOM, never the only copy.

Mechanically this inverts today's arrangement: the components stop tooltipping by
default and gain an opt-in the four auth pages set, rather than every one of the
700-odd call sites inheriting it.

**The layout question, decided by looking at it:** the message's line is
**reserved whether or not there is anything to say**. Three treatments were built
behind a switch and stacked, each with a field under it so the movement had
somewhere to show — the message appearing, the message animating open on a grid
row, and the line simply always being there.

Reserving it won because the other two move what is below at the moment a user is
reading or typing, and animating the movement makes it legible without making it
stop.

The reserved line has to be **exactly one `line-height` tall**, and the component
has to set that line-height itself rather than inherit it. Inherited it was 21px
against a reserved 20px, and the field below still moved -- by one pixel, which
is both visible and precisely what reserving the line is for. Left inherited, a
later change to the base typography would move every form again, silently and by
a few pixels.

The price is real and should be stated: every field is permanently taller, so a
twelve-field form carries twelve empty lines, which is felt most on a phone. If
that turns out to be too much on a long form, the fallback is the animated slot,
not the instant one.

## Phases

### Phase 0 — Build it and look at it — **DONE**

~200 lines of unscoped CSS in the visual-tests forms page, reaching nothing
else. Every decision above was made against it, and four were reversed by it.

### Phase 1 — Tokens, then the fields — **DONE**

`FormInput` and `FormTextarea` onto the language. The field height becomes a
token: the preview hard-codes `43px` to centre a control beside a field, and
that number quietly stops being right the moment anyone changes it.

### Phase 2 — The boxes you tick — **DONE**

`FormCheckbox`, `RadioList`, `FormToggle`. Carries F4 (one line), D3, D7, and
the `background-clip` from F11.

### Phase 3 — Error messages — **DONE**

The message gets a real element, a place in the layout and `aria-describedby`,
per D8 — which means touching all six components, since every one of them puts
the message in a tooltip and nowhere else. `RadioList` gets an error state at
all (F9).

This is the phase that is about accessibility rather than appearance, and it is
the one most likely to be cut for time — it should not be.

### Phase 4 — The rest of the surface — **DONE**

`FormFileInput` (53 tags, the largest uncovered), `FilterGroup`'s trigger — the
gap #4371 deliberately left — `FormDatePicker`, `Slider`, `Toggle`, and a
decision about `v-select-overrides.scss` (F1).

### Phase 5 — Verify

Keyboard walkthrough of every control; the error states page in both
treatments; and the 700-odd call sites spot-checked where they carry props the
visual-tests page does not.

## Open questions

1. **Nothing structural is left open.** The three the plan started with are
   settled: the field height became `--field-h` (F14 corrected what it means),
   `RadioList`'s missing error state is the one component change still owed, and
   the vendor dropdown turned out to be an override for a package that is not
   installed (F17).

2. **`RadioList` still cannot be marked invalid.** It never calls `useField`, so
   a form has no way to reach it. That is a change in what the component _is_
   rather than how it looks, and it is the last gap in D8's coverage.

3. **`FilterGroup`'s `error` prop is the one remaining tooltip.** It is passed by
   none of its 135 call sites, so it was left rather than given a message element
   nobody would see -- and reserving a line for it would have made 135 filter
   bars taller for an unused prop. Worth resolving when something actually needs
   it.

4. **`DirectUpload` is a component tree the inventory missed**, because it is not
   named `Form*`. Its drop zone now reads the frame's colours, but its Preview,
   Modal and Actions have not been looked at.
