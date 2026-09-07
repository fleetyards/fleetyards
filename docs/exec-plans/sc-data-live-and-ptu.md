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

**Every catalogue row's `version` column ends up naming the other
environment's build.** Each loader's `update_params` carries `version:
sc_version` into `apply`, which writes the shared row, so after the PTU load no
catalogue row claimed `4.10.0-live.12519617` at all. `current_version` no longer
reads that column for Component, Commodity or Equipment, but
`InventoryLedgerEntry#item_available?` did: as a live request 0 of the 10
inventory entries pointing at a catalogue item reported available, as a PTU
request 10 of 10 — with every one of them still holding its live build row.
Fixed by asking the build row instead.

**Loadouts are single-source, and the write is destructive.** `hardpoints`
carries no `environment` or `version`, and `persist_loadout` ends with
`parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids)
.destroy_all`. The 28 model facts moved to `ModelBuild`; the loadout, which is
most of what a ship page shows, did not. This load did not demonstrate it —
`Hardpoint created=0 updated=6 unchanged=17702`, loadout fingerprint unchanged,
zero ships moved — because the two builds agree on every loadout. On a build
where they diverge, loading PTU rewrites live's ship pages. This is now item 2.

**Nothing in production can load a second environment.** `ScData::CheckJob`
asks `ScData::Source.version` — the default source only — and
`Loaders::ScData::AllJob` and `FetchesParsedTree` do the same. Nothing iterates
`ScData::Source.configured` and nothing calls `ScData::Source.with`, the seam
#4590 added for it. `Imports::ScData::AllImport` is keyed on `version` with no
`environment`, so `MAX_IMPORTS_PER_VERSION` counts two environments' loads
together and the admin ledger cannot tell them apart.
`Api::V1::ScDataController#current_version` reads the same import ledger, so it
answers for whichever load finished last. This is now item 3, and it must not
land before item 2 — giving production the ability to load PTU while loadouts
are still single-source is what turns a harmless second source into a rewrite of
live.

**`ModelModule` has no build table at all.** `ModelModulesLoader` writes
`production_status` and `description` straight onto the row and rewrites its
hardpoints, there is no `ModelModuleBuild`, and `ScData::Source::BUILDS` does
not list it. It also has no guard for a module the export stopped shipping:
`load_module_data` returns nil for a path the tree does not carry and
`resolve_loadout` indexes it immediately. All six keys were present in this
build, so it did not fire.

### 2. Hardpoints per build — before anything else

The loadout has to stop being a single set of rows that the last load to run
owns. The shape that fits both this and a loadout manager is the one the other
four catalogues already use, split one layer further:

- a **slot** — `parent` plus `sc_name` — stable across builds, which is what a
  saved loadout or a named preset can safely point at;
- a **`HardpointBuild`** carrying what the build says is in it: the component,
  `min_size`/`max_size`, `types`, `port_tags`, `required_tags`, `flags`;
- a slot the build does not describe simply has no build row, so nothing is
  destroyed and `retire_absent_builds` already implements the sweep.

Two things constrain it, both measured rather than assumed:

**Only `game_files` slots may carry build rows.** `hardpoints.source` is
`{ship_matrix: 0, game_files: 1}`, 4,974 rows against 22,561. The ship matrix
comes from no build and has no version, so if "has a build row" were the test
for "is in this build", every ship-matrix hardpoint would read as retired from
every build — the same conflation this plan already rejected for `in_game` and
the 31 concept ships. The existing `destroy_all` is already scoped to
`game_files`, so the change stays inside that half. Whether the two slot sets
should ever be unified is a separate question: they are alternative descriptions
today, the frontend picks one per ship, and the ship-matrix set answers
`component: null` on every entry.

**There are two hardpoint tables, and the second one is dead.** `hardpoints`
(27,540 rows) is loader-owned and serves the public API. `model_hardpoints`
(26,258 rows, of which 17,933 are soft-deleted) is its predecessor: same
`source` enum (`ship_matrix: 0, game_files: 1`), created from 2020-12-20, last
written 2026-04-02 for the matrix half and 2024-05-23 for the game-files half,
**no sc_data loader touches it**, no public endpoint reads it, and only
`Admin::Api::V1::ModelHardpointsController` remains.

Its 6,077 `ModelHardpointLoadout` rows are not a preset system, which is what
they look like from the class name. They sit over 2,662 parent hardpoints, ~2.3
each, and their names are game-file port names — `missile_01_attach` 938 times,
`hardpoint_class_2` 795, `turret_left` 199. They are **nested sub-ports**, which
is exactly what `hardpoints` now does through `parent_type: "Hardpoint"`. So
there is no curated data on that table to preserve, and the slot identity is
`hardpoints`.

`vehicle_loadout_hardpoints` still points at `model_hardpoints` rather than at
`hardpoints`, which is why a loadout manager cannot be built on it as it stands
— but with 0 rows against 319 `vehicle_loadouts` there is nothing to migrate,
only a foreign key to repoint. Deleting the legacy pair is a separate,
unblocked piece of work.

### 3. A production load path for a second environment

`ScData::CheckJob` iterating `ScData::Source.configured` rather than asking only
the default, `Loaders::ScData::AllJob` taking an environment and running its load
inside `ScData::Source.with`, and `environment` on
`Imports::ScData::AllImport` so `MAX_IMPORTS_PER_VERSION`, the admin ledger and
`current_version` stop conflating two environments. `bin/scdata load
<environment>` already goes through that seam and is the shape to follow.

The config pointer belongs here rather than on its own: an entry naming a build
nothing loads makes that source simply not appear, which is quiet rather than
loud.

**Gated on item 2.** Until the loadout carries a build, this hands production
the ability to overwrite live's ship pages with a PTU build.

### 4. Contract phase — 73 columns still held twice

Measured against the current schema:

| Catalogue | Facts on both tables |
| --------- | -------------------- |
| Model     | 28 |
| Equipment | 23 |
| Component | 19 |
| Commodity | 3  |

Model, in full: `cargo_holds`, `external_fuel_tanks`, `fuel_consumption`,
`ground`, `ground_acceleration`, `ground_decceleration`, `ground_max_speed`,
`ground_reverse_speed`, `hull_doors`, `hull_health`, `hull_parts`,
`hydrogen_fuel_tanks`, `mass`, `max_speed`, `personal_inventory`, `pitch`,
`pitch_boosted`, `quantum_fuel_tanks`, `refuel_boom`, `reverse_speed_boosted`,
`roll`, `roll_boosted`, `scm_speed`, `scm_speed_boosted`,
`signature_cross_section`, `weapon_pool_size`, `yaw`, `yaw_boosted`.

Every one is a place a row and its build can drift. Reads already go through the
build, so dropping them is mechanical — but it is one-way, and the PTU load that
(1) was gating it on has now happened. What it should wait on instead is (2):
the columns are the fallback that makes a bad load survivable, and a load is not
yet survivable while it rewrites the other environment's loadouts.

### 5. Patch-by-patch compare

What appeared, changed and vanished between two builds — live→PTU, or version N
against N-1. Now cheap, because each catalogue retains `BUILDS_RETAINED = 3`
builds per environment rather than deleting the old ones.

**It cannot reuse `ScData::Source.available`.** That list deliberately hides
everything behind the default, which is exactly what a comparison needs. This
feature wants its own list built from the existing build rows, plus a second
selection point — "compare against what" — which the one-of-n switch is the
wrong control for.

### 6. Out of the model work

- The bulk action on `sc_data_unlisted_models`, so a patch's new entries can be
  triaged in one pass rather than row by row.
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
  loadout, the missing production load path, and `ModelModule`. Two are fixed,
  two are (2) and (3). The columns are still there, which is what keeps a bad
  load survivable — do not drop them before (2).
- **A stale generated API client reads as a broken branch.** The TS clients are
  gitignored; after a rebase onto a main that changed the schema, run
  `pnpm generate-api-client` and `pnpm generate-cable-client` before believing
  `tsc`.
- **The config is the only thing naming a version.** `bin/scdata parse <env>`
  rewrites its own entry and leaves the others alone, so live and PTU can be
  parsed independently — but a hand-edited entry pointing at a tree nobody
  loaded makes that source simply not appear, which is quiet rather than loud.
