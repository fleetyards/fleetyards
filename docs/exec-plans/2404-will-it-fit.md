# Display "Will it Fit" information on ship detail

## Goal

A ship's page names the ships that can carry it, grouped by the kind of berth — and one rule answers that question everywhere, instead of the two that disagreed.

## Context

The filter existed and #4854 made it work. What it could never do is *tell* anybody anything: it narrows a list, so the answer only exists as an absence of other ships. The issue asks for the statement.

Two things had to be settled first.

**The data is fine, which took two wrong measurements to establish.** `docks` holds 419 rows and only 25 carry dimensions, which reads as a feature blocked on missing data. But 391 of those rows belong to nothing — leftovers from the stations cleanup, now #4852. Against the docks that belong to a ship it is **25 of 28**, and 21 of the 23 models with docks are fully measured.

**There were two rules.** The ship list compared against every dock with 0.5m of clearance and no notion of dock type. The hangar took the largest ship and vehicle dock, told ground vehicles from ships, and allowed 2m. As filters that was survivable — nobody sees both answers at once. As a statement on a page it is not.

Resolves #2404. Depends on #4854, which had to land first.

## Decisions

### D1 — The hangar's rule is the one that survives

It is the one that knows a garage from a landing pad, and its clearances are the more realistic. The ship list's filter now gives the same answers, which means it became stricter: 2m instead of 0.5m, and a ground vehicle is no longer offered a landing pad.

### D2 — The rule lives on `Dock`

`SHIP_DOCK_TYPES` / `VEHICLE_DOCK_TYPES`, the two clearance sets, `largest_ship_dock` / `largest_vehicle_dock`, `clearance` and `fits?`. A `dockingport` is in neither list: it is a connection, not a place a hull is set down.

Only the largest dock of a kind is consulted — docks of a kind nest by size, so nothing that misses the biggest fits a smaller one.

### D3 — No cleverness about rotation

A containment test that sorted the dimensions would be more forgiving and would sidestep the axis-order problem in `models`. It is not done, because the axis data is known to be unreliable — the Nox is stored as 1.45 × 1.32 × 5.15, with length and height swapped — and inventing a rule on top of unreliable inputs produces answers that are confidently wrong. A wrong "it fits" is worse than no answer.

### D4 — `carriedBy` renders outside the cached fragment

`_model.jbuilder` caches on a key built from this model. The answer depends on *other* models' docks, so inside that block a changed dock would be preserved as a stale claim. `show.jbuilder` adds it after the partial.

### D5 — Detail payload only

It is in `ModelExtended`, not `Model`. On a list it would walk every carrier once per row.

### D6 — Grouped by berth, not a flat list

"It fits in a garage" and "it fits in a hangar" are different answers, and a flat list of names hides which is which.

## What changed

1. `Dock` carries the rule.
2. `WillItFitConcern` holds the one filter implementation; both controllers use it and the ship list lost its own.
3. `Model#carried_by_with_docks` pairs each carrier with the dock that takes this ship.
4. `carriedBy` on `ModelExtended` and in `show.jbuilder`.
5. `CarriedByList` on the ship page, beside the paints, modules, upgrades, variants and loaners sections.
6. Copy in all seven locales, including labels for the five dock types.

## Intent Verification

- [ ] **A ship names its carriers**, grouped by berth
- [ ] **A ground vehicle is offered garages, not landing pads**
- [ ] **A ship nobody measured says nothing** rather than "nothing carries it"
- [ ] **The filter and the page agree** — same rule, same answer
- [ ] **The list filter still works** after losing its own implementation

## Key files

| File | Role |
|------|------|
| `app/models/dock.rb` | The rule |
| `app/controllers/concerns/will_it_fit_concern.rb` | The one filter implementation |
| `app/models/model.rb` | `carried_by_with_docks` |
| `app/views/api/v1/models/show.jbuilder` | Outside the cache on purpose |
| `app/frontend/frontend/components/Models/CarriedByList/index.vue` | The section |

## Not in scope (deferred)

- **The 391 orphaned docks** — #4852. They distorted the measurement that nearly got this issue closed as blocked, but they change no answer.
- **The reverse view** — a carrier's page listing what it can take. `dockCounts` is already in the payload and rendered nowhere, so it is close; it is a different question and deserves its own decision.
- **Rotation** — see D3. Worth revisiting if the axis data is ever cleaned up.

## Discovery Log

- **2026-09-10** Built. Measured the rule against production: Carrack takes 46 models, Polaris 140, 890 Jump 106. The Cutlass Black fits nowhere, which looked wrong and is not — it is 11.5m tall and the tallest measured hangar offers 10m. I had checked its length and missed its height.
- **2026-09-10** Research. Concluded twice, wrongly, before measuring properly: first that the data was complete (read the columns, not the rows), then that it was missing (counted 419 docks instead of the 28 that belong to a ship).

## Progress

- [x] One rule, on `Dock`
- [x] Both filters on it
- [x] `carriedBy` in the API
- [x] The section on the page
- [ ] Manual check against a running dev server
