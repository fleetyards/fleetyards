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

Four catalogues carry builds. `ScData::Source` answers which one is in force,
`ScData::Current` scopes it per request and per job, and the switch appears in
the header only when more than one source is on offer.

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

### 1. A real PTU load — the only unknown

Nothing has ever parsed a PTU tree. As of writing, the development database
holds 21 hand-made `EquipmentBuild` rows for PTU and **zero** model, component
and commodity rows. Everything above is therefore proven against live plus a
fabricated second source.

The path is `bin/scdata sync ptu` → `parse ptu` → the four catalogue loaders.
Two things to expect:

- The sync is serial `s3cmd`, roughly 52 files a minute against 5,529 — about a
  day for a raw export. Worth fixing first, and the multipart-ETag trap makes a
  naive parallel rewrite re-download everything.
- The loaders have only ever written one environment. This is where a second
  tree will find whatever assumption is still single-source.

Do this before the contract phase. Dropping the columns while the second source
is still hypothetical removes the fallback that makes a bad load survivable.

### 2. Contract phase — 73 columns still held twice

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
build, so dropping them is mechanical — but it is one-way, so it waits on (1).

### 3. Patch-by-patch compare

What appeared, changed and vanished between two builds — live→PTU, or version N
against N-1. Now cheap, because each catalogue retains `BUILDS_RETAINED = 3`
builds per environment rather than deleting the old ones.

**It cannot reuse `ScData::Source.available`.** That list deliberately hides
everything behind the default, which is exactly what a comparison needs. This
feature wants its own list built from the existing build rows, plus a second
selection point — "compare against what" — which the one-of-n switch is the
wrong control for.

### 4. Out of the model work

- The bulk action on `sc_data_unlisted_models`, so a patch's new entries can be
  triaged in one pass rather than row by row.
- The five vendor component sets behind the `collector_*` and `exec_*` variants
  (`collector_military`, `collector_stealth`, `collector_indust`,
  `exec_military`, `exec_stealth`) are reusable product lines, not per-ship
  loadouts. They would make good named loadout presets at model level, where
  Fleetyards currently has nothing — `VehicleLoadout` exists only per vehicle.
  The ignored rows in `sc_data_unlisted_models` are the source list, since rows
  are kept with `last_seen_version` rather than deleted.

## Verification

- `test/lib/sc_data/source_test.rb` — which source is in force, and which are
  offered.
- `test/integration/api/v1/sc_data_*.rb` — the endpoint, the request parameter
  and the version it reports.
- `test/loaders/sc_data/` — a loader writing a build rather than a column.
- A loader test reads the *pushed* parsed tree, so a parser change lands green
  and the next version bump inherits the failures. Re-parse when the parser
  changes.

## Risks

- **A second tree exposes single-source assumptions in the loaders.** Mitigated
  by doing (1) before (2), while the columns are still there.
- **A stale generated API client reads as a broken branch.** The TS clients are
  gitignored; after a rebase onto a main that changed the schema, run
  `pnpm generate-api-client` and `pnpm generate-cable-client` before believing
  `tsc`.
- **The config is the only thing naming a version.** `bin/scdata parse <env>`
  rewrites its own entry and leaves the others alone, so live and PTU can be
  parsed independently — but a hand-edited entry pointing at a tree nobody
  loaded makes that source simply not appear, which is quiet rather than loud.
