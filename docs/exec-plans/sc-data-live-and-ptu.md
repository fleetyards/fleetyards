# SC Data: live and PTU side by side

## Goal

Fleetyards reads one build of the game data. It should be able to hold several
— live and PTU — and let a reader choose which one they are looking at, without
either build overwriting the other and without the catalogue ever showing two
competing numbers for the same thing.

The shape that makes this possible is **a row per build**: every fact the export
states lives in a `*_build` row carrying `environment` and `version`, and the
catalogue row keeps only what Fleetyards itself decides (slug, images,
curation). Reads resolve against whichever build the request asked for.

## Where it stands

Landed on `main`, in the order it was built:

**Foundations**
- #4512 resolve the build through one object
- #4514 route every loader write through one seam
- #4467 / #4520 characterize and split `update_loadout`

**A row per build, per catalogue** — the table, then the reads, then the
filters:
- Equipment: #4522, #4530, #4532
- Components: #4557, #4559, #4560
- Commodities: #4563 (small enough to be one PR)
- Models: #4566, #4567, #4571, #4581

**Model facts the columns had been holding**
- #4586 derive acceleration from the thrusters, #4587 show it in seconds

**Choosing a source**
- #4590 answer which build to read, per request and per job
- #4591 the reader-facing switch
- #4593 answer "is it in the game" per source

**A real second source**
- #4752 fetch a raw export in parallel, which is what made a second sync
  affordable at all
- #4753 ask the build, not the row's version column, whether an item is still
  in the game
- #4754 refetch the parsed tree after re-parsing live

**Hardpoints per build** — the loadout stopped being one set of rows whichever
load ran last owns:
- #4759 the table and the slot's natural key, #4761 read a hardpoint's facts
  through its build, #4762 retire a build instead of destroying the slot
- #4773 let `in_build` tolerate an environment with no builds yet, #4779 derive a
  model's facts from this build's slots only
- #4772 remove the legacy code, #4798 drop the legacy tables themselves
- #4782 / #4785 the admin view the rebuild had left without one

**Model modules per build**
- #4780 existence per build, and production status following live

**A production load path for a second environment**
- #4774 load every configured source, not only the default

**Patch-by-patch compare**
- #4795 the comparer, #4797 the endpoints, #4799 the admin page, #4800 its
  padding

**Retention and reporting**
- #4801 retention is a property of the environment: live 3, ptu 2
- #4808 the unlisted-models report, from the load that actually runs

Four catalogues carry builds. `ScData::Source` answers which one is in force,
`ScData::Current` scopes it per request and per job, and the switch appears in
the header only when more than one source is on offer. Since 2026-09-07 that is
proven against a real PTU build rather than a fabricated one — see (1).

## Decisions worth not relitigating

Each of these was measured or tested before it was decided. They are recorded
here because the reasoning is not visible from the code alone.

**A filter over two tables must not COALESCE.** An expression spanning the row
and its build drops every index. Measured on equipment: 5.18ms against 0.13ms.
The pattern is a joined `<table>_facts` alias instead.

**Except for models, which need a correlated subquery.** `Vehicle` sorts by
`modelMass` and friends through its `model` association and *ransack builds that
join itself*, so an alias nobody joined raises `PG::UndefinedTable`. The
subquery resolves one row per model, not per result row, so Postgres memoizes on
`vehicles.model_id`. Measured against the columns on the real hangar, then 1.57M
vehicles: the only case that costs anything is the biggest fleet, 0.22ms.

**`in_game` cannot be the filter for the model catalogue.** 31 of the 246 models
at the time were concept ships no build will ever describe, and they belong in
the catalogue.

**The export never says whether a player can own a ship.** 1,109 model files
against 215 in game. Three mechanical classification rules were tested and all
three fail — item-port count, filename patterns, and mechanical difference from
the base. `aegs_idris_p_collector_military` and `aegs_reclaimer_pu_hijacked` are
mechanically identical to their base ships; one is ownable and one is a mission
prop. So the RSI matrix stays the thing that creates a `Model`, and what is
worth building is a per-build diff a person reviews — 5-20 rows a patch rather
than 161 once.

**A source is offered only while it is ahead of the default.** A PTU cycle ends
with live catching up and passing it while the config still names the PTU build,
so without this the switch went on serving an older build behind the newer
label. Sources order by version first and by the id of the build carrying it
second (`4.10.0-live.12519617`); the id must be the tiebreak rather than the key,
because the case this catches is live and PTU on the *same* version with live's
id higher, which comparing versions alone reads as a draw.

**Fleetyards shows one value.** Where two sources disagree about a fact, the app
does not show both. Curation belongs in admin, and the public page shows the one
number we stand behind.

## What is left

### 1. A real PTU load — done, 2026-09-07

`4.10.1-ptu.12578875` is synced, parsed, pushed to `s3://fltyrd-sc/parsed/ptu/`
and loaded. All four catalogues wrote PTU build rows — `ComponentBuild` 7,275,
`EquipmentBuild` 4,849, `CommodityBuild` 232, `ModelBuild` 215 — and
`ScData::Source.available` offered both sources for the first time with a real
second build behind it. No exception anywhere in the load.

Measured, on one developer machine, so the next person can budget:

| | |
| --- | --- |
| `sync ptu` | 8m51s for 77,247 objects / 3.9 GB, then 24s to confirm unchanged |
| `parse` | 6m11s (ptu), 5m51s (live) — **not** the ~100 minutes recorded earlier |
| load | 10m35s (ptu), 11m15s (live) |
| `push` | 1m16s for 15,107 objects |

**The build was a three-file patch.** Re-parsed with the same parser on both
sides, `4.10.1-ptu.12578875` differs from `4.10.0-live.12519617` by two
equipment files and one item, nothing removed, and **zero** of the 15,104 shared
files differing in content. That made it the mildest possible first load, and it
is worth knowing when reading the results below: a mechanism that only bites
when loadouts diverge could not bite here.

**The live tree in the bucket was older than the parser.** #4746 added
`port_tags` and `required_tags` to loadout entries, and the slot `types`,
`min_size`, `max_size` and `flags` were not in the pushed tree either —
`models/` was 20 MB against 36 MB fresh. A loader reads the pushed tree, so
those changes had never reached anything that runs. Re-parsed and pushed (8,371
of 15,104 files updated, none added or removed) with the CI cache key bumped to
`v2`. Nothing user-facing depended on it: no jbuilder and no filter reads those
columns yet.

### What the load found

*Written on 2026-09-07, as the record of what a first real second tree exposed.
Three of the four have since been fixed and are marked; the first still
describes current behaviour. Re-verified against the code on 2026-09-09.*

**Every catalogue row's `version` column ends up naming the other
environment's build.** — *still true: the loaders still write `version:
sc_version` onto the shared row. Only the consumer that misread it was fixed.* Each loader's `update_params` carries `version:
sc_version` into `apply`, which writes the shared row, so after the PTU load no
catalogue row claimed `4.10.0-live.12519617` at all. `current_version` no longer
reads that column for Component, Commodity or Equipment, but
`InventoryLedgerEntry#item_available?` did: as a live request 0 of the 10
inventory entries pointing at a catalogue item reported available, as a PTU
request 10 of 10 — with every one of them still holding its live build row.
Fixed by asking the build row instead.

**Loadouts are single-source, and the write is destructive.** — *fixed, #4762.
`destroy_all` is gone from `persist_loadout`; `retire_absent_slots` retires the
build row and leaves the slot.* `hardpoints`
carries no `environment` or `version`, and `persist_loadout` ends with
`parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids)
.destroy_all`. The 28 model facts moved to `ModelBuild`; the loadout, which is
most of what a ship page shows, did not. This load did not demonstrate it —
`Hardpoint created=0 updated=6 unchanged=17702`, loadout fingerprint unchanged,
zero ships moved — because the two builds agree on every loadout. On a build
where they diverge, loading PTU rewrites live's ship pages. This is now item 2.

**Nothing in production can load a second environment.** — *fixed, #4774.
`CheckJob` iterates `ScData::Source.configured` and `AllJob` runs inside
`ScData::Source.with`.* `ScData::CheckJob`
asks `ScData::Source.version` — the default source only — and
`Loaders::ScData::AllJob` and `FetchesParsedTree` do the same. Nothing iterates
`ScData::Source.configured` and nothing calls `ScData::Source.with`, the seam
#4590 added for it. `Api::V1::ScDataController#current_version` reads the import
ledger without naming a source, so it answers for whichever load finished last.
And `CheckJob`'s coverage check asks the catalogues' own `version` columns, which
are shared between environments and rewritten wholesale by a load — so after a
ptu load it reads a finished live build as never loaded.

The ledger itself needs nothing, which an earlier version of this note got
wrong: it claimed `MAX_IMPORTS_PER_VERSION` conflates two environments and that
an admin cannot tell their loads apart. A version names its environment —
`4.10.1-ptu.12578875` — so it is already unique across sources, the count is
already per build, and the version the admin view shows already says which
source a load was for. This is now item 3, and it must not
land before item 2 — giving production the ability to load PTU while loadouts
are still single-source is what turns a harmless second source into a rewrite of
live.

**`ModelModule` has no build table at all.** — *fixed, #4780. `ModelModuleBuild`
exists, `ScData::Source::BUILDS` lists it, and `load_module_data` returning nil
is guarded.* `ModelModulesLoader` writes
`production_status` and `description` straight onto the row and rewrites its
hardpoints, there is no `ModelModuleBuild`, and `ScData::Source::BUILDS` does
not list it. It also has no guard for a module the export stopped shipping:
`load_module_data` returns nil for a path the tree does not carry and
`resolve_loadout` indexes it immediately. All six keys were present in this
build, so it did not fire.

### 2. Hardpoints per build — done except (5), 2026-09-08

The loadout has to stop being a single set of rows that the last load to run
owns. That is the whole reason, and it needs no other: the shape is the one the
other four catalogues already use, split one layer further, because a loadout
differs between builds in *structure* and not only in facts.

- a **slot** — `parent` plus `sc_name` — stable across builds, which is what
  `ModelPosition` already points at;
- a **`HardpointBuild`** carrying what the build says is in it: the component,
  `min_size`/`max_size`, `types`, `port_tags`, `required_tags`, `flags`;
- a slot the build does not describe simply has no build row, so nothing is
  destroyed and `retire_absent_builds` already implements the sweep.

Two things constrain it, both measured rather than assumed:

**Only `game_files` slots may carry build rows.** `hardpoints.source` is
`{ship_matrix: 0, game_files: 1}`. The `game_files` half is 22,561 rows on every
dump checked; the matrix half is not stable — 4,974 when this was written,
10,750 on a later dump — because a ship-matrix import rewrites it. The ratio is
the point, not the figure. The ship matrix
comes from no build and has no version, so if "has a build row" were the test
for "is in this build", every ship-matrix hardpoint would read as retired from
every build — the same conflation this plan already rejected for `in_game` and
the 31 concept ships. The existing `destroy_all` is already scoped to
`game_files`, so the change stays inside that half. Whether the two slot sets
should ever be unified is a separate question: they are alternative descriptions
today, the frontend picks one per ship, and the ship-matrix set answers
`component: null` on every entry.

**There were two hardpoint tables, and the second one was dead.** *The second is
gone — #4772 removed the code, #4798 dropped the table. What follows is the case
for dropping it.* `hardpoints` is loader-owned and serves the public API.
`model_hardpoints` (26,258 rows, of which 17,933 were soft-deleted) was its
predecessor: same `source` enum (`ship_matrix: 0, game_files: 1`), created from
2020-12-20, last written 2026-04-02 for the matrix half and 2024-05-23 for the
game-files half, **no sc_data loader touched it**, no public endpoint read it,
and only `Admin::Api::V1::ModelHardpointsController` remained.

Its 6,077 `ModelHardpointLoadout` rows are not a preset system, which is what
they look like from the class name. They sit over 2,662 parent hardpoints, ~2.3
each, and their names are game-file port names — `missile_01_attach` 938 times,
`hardpoint_class_2` 795, `turret_left` 199. They are **nested sub-ports**, which
is exactly what `hardpoints` now does through `parent_type: "Hardpoint"`. So
there is no curated data on that table to preserve, and the slot identity is
`hardpoints`.

`vehicle_loadout_hardpoints` pointed at `model_hardpoints` rather than at
`hardpoints`, and never held a row. It was not a constraint on this work in
either direction: the *live* vehicle-loadout feature is a bookmark — every
`vehicle_loadouts` row carries a URL to `spviewer.eu` or `erkul.games` and none
is blank, which held on both dumps checked on 2026-09-09 — so it reads no
hardpoints and knows nothing about builds. The two share the word "loadout" and
nothing else. *Dropped in #4798.*

### 3. A production load path for a second environment — done, 2026-09-08

Landed as #4774. `ScData::CheckJob` iterates `ScData::Source.configured`,
`Loaders::ScData::AllJob` takes an environment and runs its whole load inside
`ScData::Source.with`, and the coverage check reads the build rows. The
description below is what was built.


`ScData::CheckJob` iterating `ScData::Source.configured` rather than asking only
the default, `Loaders::ScData::AllJob` taking an environment and running its
whole load inside `ScData::Source.with`, `current_version` answering for the
source in force, and the coverage check reading the build rows rather than the
catalogues' shared `version` columns. `bin/scdata load <environment>` already
goes through that seam and is the shape to follow.

No column is added to `Imports::ScData::AllImport`. A version names its
environment, so the ledger is already per source.

The config pointer belongs here rather than on its own: an entry naming a build
nothing loads makes that source simply not appear, which is quiet rather than
loud.

**Gated on item 2.** Until the loadout carries a build, this hands production
the ability to overwrite live's ship pages with a PTU build.

### 4. Model modules per build — done, 2026-09-08

`ModelModule` was the one catalogue the row-per-build work never covered, and
what it was missing was not facts but **existence**. A module row is created by
`ModulesImporter` from the RSI store data or by an admin, never by a load, and it
is shared by every source. So a module only the PTU build described was offered
under live as well, with `description` from whichever load ran last and a loadout
that resolved to nothing — its slots carry `HardpointBuild` rows for ptu and not
for live.

Measured before deciding: 27 module rows, **6 with an `sc_key`**, and exactly
those 6 have slots. The loader writes three things, of which one is an export
fact. On that count a table looks unjustifiable, and an earlier version of this
plan said so — weighing the fields and missing that the value is the question
"does this build describe it", which is the one a PTU-only module raises.

`ModelModuleBuild` holds `description` and `cargo_holds`;
`ModelModule.in_build` narrows the modules a ship offers; `ScData::Source::BUILDS`
lists it, so a source can now count as loaded on modules alone.

Two things deliberately left alone:

- **`cargo_holds` is recorded but not read through.** `set_cargo_from_hardpoints`
  derives `cargo` from it in a `before_save`, so a reader answering from the
  build would hand that callback the *previous* build's value on the second load
  and store a capacity the module does not have. Same reason `ComponentBuild`
  holds back `manufacturer_id` and `hidden`.
- **`production_status` stays on the row.** The loader hardcodes it to
  "flight-ready" while the admin API also permits it, so it is a
  load-versus-curation conflict that predates the table and wants deciding on
  its own rather than being quietly settled by moving it.

### 5. Contract phase — 87 columns still held twice

Re-measured 2026-09-09, by intersecting each build class's `FACTS` with its
row's `column_names`:

| Catalogue | Facts on both tables |
| --------- | -------------------- |
| Model     | 30 |
| Equipment | 23 |
| Component | 19 |
| Hardpoint | 10 |
| Commodity | 3  |
| ModelModule | 2 |
| **Total** | **87** |

An earlier revision of this file said 73, counting only the four catalogues and
predating two facts. Model has since gained `main_acceleration` and
`retro_acceleration`; `Hardpoint` and `ModelModule` became dual-held when they
got build rows, and belong to the same contract phase — hardpoints via step (5)
of [sc-data-hardpoints-per-build.md](sc-data-hardpoints-per-build.md), which
folds into this item.

Model, in full: `cargo_holds`, `external_fuel_tanks`, `fuel_consumption`,
`ground`, `ground_acceleration`, `ground_decceleration`, `ground_max_speed`,
`ground_reverse_speed`, `hull_doors`, `hull_health`, `hull_parts`,
`hydrogen_fuel_tanks`, `main_acceleration`, `mass`, `max_speed`,
`personal_inventory`, `pitch`, `pitch_boosted`, `quantum_fuel_tanks`,
`refuel_boom`, `retro_acceleration`, `reverse_speed_boosted`, `roll`,
`roll_boosted`, `scm_speed`, `scm_speed_boosted`, `signature_cross_section`,
`weapon_pool_size`, `yaw`, `yaw_boosted`.

Hardpoint: `category`, `component_id`, `flags`, `group`, `group_key`,
`max_size`, `min_size`, `port_tags`, `required_tags`, `types`.

ModelModule: `cargo_holds`, `description`.

The count is derivable, so it should be re-measured rather than trusted:

```ruby
build::FACTS.map(&:to_s).select { |fact| row.column_names.include?(fact) }
```

Every one is a place a row and its build can drift. Reads already go through the
build, so dropping them is mechanical — but it is one-way, and the PTU load that
(1) was gating it on has now happened.

**Still open, and now the largest thing left.** It was waiting on (2), which
landed on 2026-09-08: the loadout carries a build, so a load no longer rewrites
the other environment's ship pages. What it should wait on now is a PTU load
having run *in production* — the columns are the fallback that makes a bad load
survivable, and no second environment has been loaded there yet. #4774 gave
production the ability; nothing has exercised it.

### 6. Patch-by-patch compare — done, 2026-09-08

Landed as #4795 (the comparer), #4797 (`/sc-data/builds` and `/sc-data/compare`),
#4799 (the admin page) and #4800. Planned in
[sc-data-build-compare.md](sc-data-build-compare.md), which carries the
measurements behind computing rather than recording.

Two things the real data taught, both worth keeping:

- **A catalogue with no rows on one side was never recorded for that build**, and
  saying "everything appeared" instead is a wrong answer, not a rough one.
  Comparing live 4.9.0 with 4.10.0 announced all 232 commodities and all 215
  models as new until the endpoint learned to say so. Production confirms it on
  the first day: two of four catalogues answer `recorded: false`.
- **The oldest retained build is a backfill, not a record of that build.** Every
  `*_builds` backfill stamped the then-current column values with the current
  version label, so any comparison whose older side is that build measures the
  backfill. Decided 2026-09-08: leave it, since it ages out of the retention
  window. Do not read the first comparison against the oldest build as a patch
  diff.

What appeared, changed and vanished between two builds — live→PTU, or version N
against N-1. Cheap because each catalogue retains several builds per environment
rather than deleting the old ones — see `ScData::Source::BUILDS_RETAINED`, which
since #4801 keeps 3 for live and 2 for ptu.

**It cannot reuse `ScData::Source.available`.** That list deliberately hides
everything behind the default, which is exactly what a comparison needs. This
feature wants its own list built from the existing build rows, plus a second
selection point — "compare against what" — which the one-of-n switch is the
wrong control for.

### 7. Out of the model work

- The bulk action on `sc_data_unlisted_models` — **done, #4661, shipped in
  v7.10.0**, the same release as the detector itself. `ignore_bulk`,
  `mark_as_paint_bulk` and `reset_bulk` on the controller, and a selection with
  two bulk buttons on `admin/pages/models/unlisted.vue`. `link` and
  `create_model` stay per row on purpose: each needs a target a person picks.
  (An earlier revision of this file listed it as open. It never was.)

  The one loose end: `reset_bulk` has a route and no button. Reset is for a
  decision made in error, which is a per-row thing, so that may be right — but it
  is an accident rather than a decision.

  What kept the feature from being usable was elsewhere: the table was empty in
  production because its only writer had no caller. The report sat in `Loaders::ScData::ModelsJob`, which
  nothing enqueues — the scheduled `Loaders::ModelsJob` is the RSI ship matrix
  loader, one namespace away. #4808 moved it to `Loaders::ScData::AllJob`, which
  `CheckJob` and the admin trigger actually run, and scoped the sweep to
  `last_seen_environment` so a per-source load does not delete the other
  environment's rows. Expect rows to appear after the first load following that
  deploy; if none do, the caller analysis was incomplete.

  `Loaders::ScData::ModelsJob` still has no caller and is now a plain
  single-catalogue loader. Deleting it and its tests is undecided.
- The five vendor component sets behind the `collector_*` and `exec_*` variants
  (`collector_military`, `collector_stealth`, `collector_indust`,
  `exec_military`, `exec_stealth`) are reusable product lines, not per-ship
  loadouts. They would make good named loadout presets at model level, where
  Fleetyards currently has nothing — `VehicleLoadout` exists only per vehicle.
  `ModelHardpointLoadout` is not a counter-example despite the name: it is
  nested sub-ports on the dead legacy table, see (2). The ignored rows in
  `sc_data_unlisted_models` are the source list, since rows are kept with
  `last_seen_version` rather than deleted.

## Verification

**Every figure in this file was re-checked on 2026-09-09** against the code, the
production dump and, where the endpoint allows it, production itself. What
changed as a result is recorded in place: the contract-phase count (73 → 87), the
hardpoint PR list, the bulk action (never open), and status marks on the findings
under (1) that have since been fixed. Counts that turned out to depend on which
dump you ask are now labelled as such — the `game_files` slot count is stable at
22,561, the ship-matrix half is not.

- `test/lib/sc_data/source_test.rb` — which source is in force, and which are
  offered.
- `test/integration/api/v1/sc_data_*.rb` — the endpoint, the request parameter
  and the version it reports.
- `test/loaders/sc_data/` — a loader writing a build rather than a column.
- A loader test reads the *pushed* parsed tree, so a parser change lands green
  and the next version bump inherits the failures. Re-parse when the parser
  changes — #4746 shipped without one and the debt sat in the bucket for two
  days. Run `test/loaders/sc_data/`, `test/parsers/sc_data/` and
  `test/lib/sc_data/` against the re-parsed tree *before* pushing it, and bump
  the CI cache key prefix when the version has not moved.

## Risks

- **A second tree exposes single-source assumptions in the loaders.** This was
  the point of doing (1) first, and it found four: the `version` column, the
  loadout, the missing production load path, and `ModelModule`. All four are
  addressed — the last three by (2), (3) and (4), and the `version` column by
  fixing its one bad consumer rather than the column itself, which the loaders
  still write. The dual-held columns are still there, which is what keeps a bad
  load survivable; the gate on dropping them is no longer (2) but a PTU load
  having run in production. See (5).
- **A stale generated API client reads as a broken branch.** The TS clients are
  gitignored; after a rebase onto a main that changed the schema, run
  `pnpm generate-api-client` and `pnpm generate-cable-client` before believing
  `tsc`.
- **The config is the only thing naming a version.** `bin/scdata parse <env>`
  rewrites its own entry and leaves the others alone, so live and PTU can be
  parsed independently — but a hand-edited entry pointing at a tree nobody
  loaded makes that source simply not appear, which is quiet rather than loud.
