# Ship detail — the landed and extended states, not just the retracted one

Issue: #5030

## Goal

One state selection on the ship page — retracted, extended or landed — offered only for the states
a model actually has, driving the four fleetchart views, the holo (big, inline and popped out) and
the three dimension tiles on the Base metrics card.

## What exists today

The record carries all three families and the public API serves all three. `MeasureHoloJob` fills
`{extended,landed}_{length,beam,height}` from the holo of that state, so the figures are measured
rather than typed. The site reads one boolean, `extendedStateVisible`, set by a two-button toggle
above the views in `Models/FleetchartImages`, and read by the holo and `Models/BaseMetrics` on
`pages/ships/[slug]`. Landed appears nowhere.

`aegs-sabre-raven-ex` is the first model with a full landed set — holo, eight views, and 4.24 m of
landed height against 3.28 m in flight.

## Decisions

**D1 — two controls, one state.** The selector stays above the views and also appears beside
`3D View` in the image toolbar when the model has more than one holo. The holo is at the top of the
page and its only control was at the bottom.

**D2 — "Retracted" stays, "Landed" is new.** `labels.model.state.retracted` is already translated
in all seven locales and is the admin form's vocabulary; only `landed` is added, by hand, in each.

**D3 — the ship detail page only.** The fleetchart's own extended state (`shared/stores/fleetchart`,
per namespace) is a different control on a different page.

**D4 — fallback per view and per model.** A state missing one view falls back to the retracted image
for that view, which is what the Extended toggle does today. A state persisted from another ship that
this one does not have reads as retracted.

**D5 — one figure, never two.** The tiles swap; they never print a second figure in parentheses.

**D6 — two lists of states, not one.** `availableStates` (a metric or any media) drives the views
toggle and keeps today's behaviour; `holoStates` (a holo of that state) drives the toolbar, so a
model with landed images but no landed holo does not get a toolbar button that changes nothing.

## Phases

| phase | what                                                                                               |
| ----- | -------------------------------------------------------------------------------------------------- |
| 1     | `useModelStates` — the enum, the media/metric maps, the two state lists, the pickers, and its spec |
| 2     | the store: `modelState` replaces `extendedStateVisible`, persisted                                 |
| 3     | `FleetchartImages` and `BaseMetrics` take a state instead of a boolean                             |
| 4     | the ship page: the toolbar selector, the holo per state, the pop-out viewer                        |
| 5     | `labels.model.state.landed` in all seven locales                                                   |

No backend phase: the payload, the schema and the generated client already carry every field.

## Log

- **2026-09-18** Built, all five phases, in #5033. Three things the plan did not say.

  `modelHasState` has to read all three dimensions, not just the length: on the first hull with a
  landed set the gear changes the height and nothing else, so a length-only test would have hidden
  the state that motivated the work.

  The fleetchart size chain skips the plain length. `state offset → state measurement → retracted
offset → length`: falling through to the retracted _length_ before the retracted _offset_ would
  draw a state with no figures of its own at a size nobody curated.

  D6 inverted for what the toolbar _lists_. A second holo is still what earns the toolbar, but it
  then offers every state in `availableStates` rather than only the ones with a holo — a model with
  a landed holo and extended images alone left the toolbar with no segment selected while the page
  sat in the extended state, and two switches on one page disagreeing is worse than a segment that
  moves the dimensions without moving the mesh.
