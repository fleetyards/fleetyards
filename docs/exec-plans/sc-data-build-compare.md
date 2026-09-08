# SC Data: comparing two builds

Item 6 of [sc-data-live-and-ptu.md](sc-data-live-and-ptu.md), written out — and
narrower than that item implies, because a good part of it already exists.

## Goal

Answer "what appeared, changed and vanished between two builds", in two shapes:

- **a patch** — build N against N-1 in the same environment
- **a preview** — live against ptu, which is the question a PTU cycle raises

## What already exists, and must not be rebuilt

The whole vertical, for **models**, within one environment:

- `ModelBuildChange` records a diff per (model, field), keyed on
  `from_version` / `to_version`, and **replaces** rather than appends — a
  re-parse of the same export can change values without a version bump, and the
  second parse is the one to keep
- `ModelsLoader` calls `ModelBuildChange.record!(build)` as it loads
- `GET /models/{slug}/changes` serves it, with its own schema components
- `Api::V1::Stats::BaseController` reads it

So the mechanism is proven. What is missing is a different axis and a different
altitude, not four more copies of it.

## What is missing, in the order worth doing it

### 1. The cross-environment axis

`ModelBuildChange.for_build(environment, version)` and its `previous_build` are
**same-environment only**: they answer "what did this patch change", never "what
does ptu have that live does not". That second question is the whole point of a
preview, and nothing answers it today.

**It needs no new table.** Both builds are present at the same time — every
catalogue retains `BUILDS_RETAINED = 3` per environment — so a live-against-ptu
diff is a join over two `(environment, version)` pairs, computed on demand.

### 2. A build-level overview

Changes are per model today: you can ask what happened to the Gladius, not what
happened in `4.10.1-ptu.12578875`. The overview is the page somebody actually
opens when a build lands.

### 3. The other catalogues

Component, equipment, commodity and model module have no recorder. Worth doing
after (1) and (2), because those two are what make the retained builds readable
at all.

## The decision the numbers settle: recorded or computed

Measured on the real data — live `4.9.0-live.12344265` against
`4.10.0-live.12519617`, components, 7,251 present in both:

| | |
| --- | --- |
| appeared | **23** |
| vanished | **61** |
| `name` changed | **10** |
| `type_data` changed | 420 |
| `size`, `grade`, `durability` changed | **0** |

Two things follow.

**Volume is not the deciding factor.** A real patch changes a few hundred fields
across seven thousand rows, and the on-demand join that produced the table above
returns instantly. Recording and computing are both cheap, so the choice is
about which questions each can answer:

- **computed** works between any two builds still retained, which covers
  live-against-ptu completely, and needs no schema
- **recorded** survives pruning, so it is the only way to see further back than
  three builds

So: compute the preview, record the history. That is why (1) comes first — it is
the half that needs nothing built underneath it.

**And the useful diff is not "which fields differ".** Two kinds of field drown
out the rest.

*Serialized shapes.* 420 components differed on `type_data`, a blob whose diff
reads as "something inside this changed". `ModelBuild` already excludes its
shapes from `DIFFABLE_FACTS`, and for a sharper reason than mine: two loads of
the same export can serialise one differently with nothing having changed, so
comparing them reports a difference on every re-parse. Worth stating precisely —
of those 420, 189 also differ in length and so are likely real; the rest may be
re-serialisation. Either way the field is not an answer.

*Prose.* Measured after the first version of this plan, and the larger of the
two: with the shapes already excluded, **2,171 of 2,182** changed components
differed on `description` alone, against 10 on `name`. Excluding it turns a page
of 2,182 into one of 359. `ModelBuild` never hit this because it carries no
description at all.

The three numbers a person wants are **appeared, vanished, renamed**.

## Constraints

**It cannot reuse `ScData::Source.available`.** That list deliberately hides
every source behind the default — which is exactly what a comparison needs to
see. This wants its own list, built from the build rows that exist rather than
from the config.

**It needs a second selection point.** "Compare against what" is a different
control from "which build am I reading", and the one-of-N switch in the header
is the wrong shape for it.

**A retired row is not a vanished one.** A catalogue row the export dropped
keeps its row and loses its build row, so "vanished" means "has no build row for
the newer build" — not "was deleted". The same distinction the loadout work
settled for slots.

## Verification

The measurement above is the fixture: a compare of live `4.9.0-live.12344265`
against `4.10.0-live.12519617` has to report 23 appeared, 61 vanished and 10
renamed for components. Those numbers come from the production dump of
2026-09-06 and are stable as long as both builds are retained.
