# SC Data: Builds, Sources and Hardpoints per Build

**Date:** 2026-09-24 (research 2026-09-07 to 2026-09-09)

Fleetyards holds several game builds side by side, live and PTU. Every fact the export states lives in a `*_build` row carrying `environment` and `version`. The catalogue row keeps only what Fleetyards decides for itself: slug, images, curation. `ScData::Source` answers which build is in force, and `ScData::Current` scopes that per request and per job. This note records the measurements and the reasoning behind that design that the code does not show: why filters look the way they do, why the export cannot decide ownability, what the first real PTU load exposed, and the constraints that shaped `HardpointBuild`. Read it before changing how a catalogue resolves its build, or before building a loadout editor on top of the slots.

## Decisions worth not relitigating

Each of these was measured or tested before it was decided.

**A filter over two tables must not COALESCE.** An expression that spans the row and its build drops every index. Measured on equipment, it took 5.18ms against 0.13ms. Use a joined `<table>_facts` alias instead.

**Models are the exception and need a correlated subquery.** `Vehicle` sorts by `modelMass` and similar fields through its `model` association, and ransack builds that join itself. An alias that nobody joined therefore raises `PG::UndefinedTable`. The subquery resolves one row per model rather than per result row, so Postgres memoizes on `vehicles.model_id`. It was measured on the real hangar and then on 1.57M vehicles. The only case that cost anything was the biggest fleet, at 0.22ms.

**`in_game` cannot filter the model catalogue.** When this was measured, 31 of the 246 models were concept ships that no build will ever describe, and they belong in the catalogue.

**The export never says whether a player can own a ship.** There are 1,109 model files against 215 ships in game. Three mechanical classification rules were tested and all three fail: item-port count, filename patterns, and mechanical difference from the base ship. For example, `aegs_idris_p_collector_military` and `aegs_reclaimer_pu_hijacked` are both mechanically identical to their base ships, but one is ownable and the other is a mission prop. So the RSI ship matrix stays the thing that creates a `Model`. What is worth building is a per-build diff that a person reviews, which comes to 5-20 rows a patch rather than 161 at once.

**A source is offered only while it is ahead of the default.** A PTU cycle ends with live catching up and passing it while the config still names the PTU build. Without this rule the switch kept serving an older build under the newer label. Sources order by version first and by build id second (`4.10.0-live.12519617`). The id has to be the tiebreak rather than the key: the case this catches is live and PTU on the _same_ version with live's id higher, and comparing versions alone reads that as a draw.

**Fleetyards shows one value.** Where two sources disagree about a fact, the public page does not show both. Curation belongs in admin.

## The first real PTU load (2026-09-07)

`4.10.1-ptu.12578875` was synced, parsed, pushed to `s3://fltyrd-sc/parsed/ptu/` and loaded with no exceptions. The load wrote `ComponentBuild` 7,275, `EquipmentBuild` 4,849, `CommodityBuild` 232 and `ModelBuild` 215 rows.

Timings from one developer machine, for budgeting:

| Step       | Time                                                                |
| ---------- | ------------------------------------------------------------------- |
| `sync ptu` | 8m51s for 77,247 objects / 3.9 GB, then 24s to confirm unchanged    |
| `parse`    | 6m11s (ptu), 5m51s (live). An older figure of ~100 minutes is wrong |
| load       | 10m35s (ptu), 11m15s (live)                                         |
| `push`     | 1m16s for 15,107 objects                                            |

**That build was a three-file patch.** Re-parsed with the same parser on both sides, `4.10.1-ptu.12578875` differed from `4.10.0-live.12519617` by two equipment files and one item. Nothing was removed, and **none** of the 15,104 shared files differed in content. That made it the mildest possible first load. Anything that only goes wrong when loadouts diverge could not go wrong here, so treat "the PTU load was clean" as weak evidence.

**The loaders still write `version:` onto the shared row.** Each loader's `update_params` passes `version: sc_version` into `apply`, which writes the catalogue row. After a PTU load, no catalogue row names the live build at all. `current_version` no longer reads that column for Component, Commodity or Equipment. `InventoryLedgerEntry#item_available?` did read it: as a live request, 0 of 10 inventory entries reported available, and as a PTU request 10 of 10, even though every one still had its live build row. That consumer was fixed by asking the build row instead. The column itself is still written, so any new reader has to ask the build and must never read `row.version`.

## Model modules: two things left alone on purpose

`ModelModuleBuild` exists because the question was whether a build describes the module at all, not how many facts it has. Only 6 of the 27 modules have an `sc_key`, and exactly those 6 have slots. Two things were deliberately not moved onto it:

- **`cargo_holds` is recorded on the build but not read through it.** `set_cargo_from_hardpoints` derives `cargo` from it in a `before_save`. A reader that answered from the build would hand that callback the _previous_ build's value on the second load, and it would store a capacity the module does not have. `ComponentBuild` holds back `manufacturer_id` and `hidden` for the same reason.
- **`production_status` stays on the row.** The loader hardcodes it to "flight-ready", and the admin API also allows editing it. That is a conflict between the load and curation that predates the build table. It needs its own decision, not a quiet settlement by moving the column.

## Patch-by-patch compare: two lessons from real data

- **A catalogue with no rows on one side was never recorded for that build.** Reporting "everything appeared" in that case is a wrong answer, not a rough one. Comparing live 4.9.0 with 4.10.0 announced all 232 commodities and all 215 models as new until the endpoint learned to answer `recorded: false`.
- **The oldest retained build is a backfill, not a record of that build.** Every `*_builds` backfill stamped the then-current column values with the current version label. Any comparison whose older side is that build measures the backfill, not a patch. It was left alone because it ages out of the retention window (`ScData::Source::BUILDS_RETAINED`: live 3, ptu 2).

The compare also cannot reuse `ScData::Source.available`. That list deliberately hides every build behind the default, and those are exactly the builds a comparison needs.

## Hardpoints per build: constraints, measured

A hardpoint is split into a slot on `hardpoints` (`parent_type`, `parent_id`, `sc_name`, `source`), which stays stable across builds, and a `HardpointBuild` row holding what a build says about that slot. A slot that a build does not describe has no build row for it and is never destroyed.

**Only `game_files` slots carry build rows.** `hardpoints.source` is `{ship_matrix: 0, game_files: 1}`. The `game_files` half is 22,561 rows on every dump checked. The matrix half is not stable, at 4,974 rows on one dump and 10,750 on a later one, because a ship-matrix import rewrites it. The ship matrix comes from no build and has no version. If "has a build row" were the test for "is in this build", every matrix hardpoint would read as retired from every build. That is the same mistake that was rejected for `in_game` and the concept ships. So the read side answers "in this build" as _either_ a matrix slot _or_ a game-files slot with a build row.

**The slot's unique index is scoped to `source = 1`.** The natural key `(parent_type, parent_id, sc_name)` has 0 duplicates across the 22,561 game-files rows. An unscoped index is impossible: there are 1,222 duplicate groups with 2,406 excess rows, and every one of them is `ship_matrix`. The matrix half is not a set of named ports at all. It repeats names by design, and a single ship carries 32 rows called "Maneuvering Thruster". "The slot called X on this parent" is well-defined on the game-files side and meaningless on the matrix side. That is a second, independent argument for keeping build rows off the matrix half.

The two slot sets are alternative descriptions of the same ship. The frontend picks one per ship, and the matrix set answers `component: null` on every entry. Nobody has measured whether the two sets line up by name.

**`Hardpoint#parent` is polymorphic across four types:**

| `parent_type` | ship_matrix | game_files                 |
| ------------- | ----------- | -------------------------- |
| `Model`       | 4,666       | 15,138                     |
| `Component`   | —           | 3,789                      |
| `Hardpoint`   | 308         | 3,617                      |
| `ModelModule` | —           | 17 (plus 5 with no source) |

Nesting stops at depth 3: 18,944 slots at depth 1, 2,979 at depth 2 and 638 at depth 3.

**Open question: Component-parented slots.** These are the sub-hardpoints of a hidden component, such as a door holding a cargo grid, and `ItemsLoader` writes them. `Component` is the one parent type that already has its own build table. Today these slots hang their facts off `HardpointBuild` like every other slot. Whether they should hang off `ComponentBuild` instead deserves a decision rather than a default. Keeping it uniform is simpler, but a component's ports describe the component, and the component is already per build.

The legacy `model_hardpoints` / `ModelHardpointLoadout` pair, now dropped, held no curated data. Its 6,077 "loadout" rows were nested sub-ports named after game-file ports (`missile_01_attach` 938 times). The saved `vehicle_loadouts` are bookmarks: all 319 rows carry an external loadout-tool URL, and none is blank.

## What this makes possible: a loadout editor

Fleetyards has no loadout editor of its own. When one is built, a user's selection is a set of `(slot → component)` pairs per vehicle, and the build split fixes three things about how it has to work:

- **The slot reference** is a foreign key to the `hardpoints` row plus the denormalised name path, which is at most three segments. The key gives integrity, and the path survives the slot row being recreated.
- **A saved selection floats rather than pins.** It means "these components in these slots", re-resolved against whichever source the reader asked for. Each entry reports whether its slot and its component are in that build, the same way inventory entries survive a patch and report that an item is no longer available. Pinning a loadout to the build it was made against would be more accurate historically, but it takes away what a player wants after a patch, which is to see their own ship against the new build.
- **Validity is checked per source, on read.** `min_size`, `max_size`, `types`, `port_tags` and `required_tags` are all build facts, so "does this component fit this slot" can have a different answer per source. A selection that is valid under live can be invalid under PTU. It cannot be validated once on write, unlike every other write path in the app. This is the part most likely to be missed.

An editor also needs a separation between a model-level preset and a user's own selection. The five vendor component sets behind the `collector_*` and `exec_*` variants are natural model-level presets.
