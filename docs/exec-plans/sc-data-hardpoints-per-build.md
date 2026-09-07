# SC Data: hardpoints per build

Item 2 of [sc-data-live-and-ptu.md](sc-data-live-and-ptu.md). Read the "what the
load found" section there first — this plan exists because of one finding.

## Goal

A loadout must stop being a single set of rows that whichever load ran last
owns. Today `hardpoints` carries no `environment` or `version`, and
`ScData::Loader::BaseLoader#persist_loadout` ends with

```ruby
parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids).destroy_all
```

so loading PTU deletes every game-file hardpoint live's loadout put there and
writes PTU's in their place. The loadout is most of what a ship page shows.

The first PTU load did not demonstrate this: `4.10.1-ptu.12578875` and
`4.10.0-live.12519617` agree on every loadout, so the run reported `Hardpoint
created=0 updated=6 unchanged=17702` with the loadout fingerprint unchanged and
zero ships moved. It is proven by reading, and it fires on the first build where
loadouts diverge — which is the next one, not this one.

## Shape

The same row-per-build the four catalogues use, split one layer further, because
a loadout differs between builds in *structure* and not only in facts:

- a **slot** stays on `hardpoints` — `parent_type`, `parent_id`, `sc_name`,
  `source`. Stable across builds, so anything pointing at a slot keeps
  resolving.
- a **`HardpointBuild`** carries what a build says about that slot:
  `component_id`, `min_size`, `max_size`, `types`, `port_tags`,
  `required_tags`, `flags`, and the three derived columns below.
- a slot the build does not describe has **no build row**. Nothing is destroyed,
  and `retire_absent_builds` already implements that sweep.

### The column split

| Column | Where | Why |
| --- | --- | --- |
| `parent_type`, `parent_id`, `sc_name` | slot | the identity; nesting is by `parent`, so a stable parent keeps children stable |
| `source` | slot | a slot comes from the matrix or the files, and that does not change per build |
| `component_id` | build | what is installed is the loadout |
| `min_size`, `max_size` | build | `slot_sizes` derives them from the installed item and the declared bounds |
| `types`, `port_tags`, `required_tags`, `flags` | build | straight from the export |
| `group`, `category`, `group_key` | build | `before_validation :set_group, :set_category, :set_group_key` derive them from the component, so they move with it |
| `matrix_key` | slot | matrix identity, not a build fact |
| `details` | slot | no writer at all: not the sc_data loader, and the only admin controller permitting it is the legacy `ModelHardpoint` one |

## Constraints, measured rather than assumed

**Only `game_files` slots may carry build rows.** `hardpoints.source` is
`{ship_matrix: 0, game_files: 1}` — 4,974 rows against 22,561. The ship matrix
comes from no build and has no version, so if "has a build row" were the test
for "is in this build", every ship-matrix hardpoint would read as retired from
every build. That is the same conflation this project already rejected for
`in_game` and the 31 concept ships. The existing `destroy_all` is already scoped
to `game_files`, so the write side of the change stays inside that half; the
read side has to answer "in this build" as *either* a matrix slot *or* a
game-files slot with a build row.

**Whether the two slot sets should ever be unified is out of scope.** They are
alternative descriptions today: the frontend picks one per ship, and
`useCompareHardpoints` notes the ship-matrix set "answers `component: null` on
every entry". Nobody has measured whether they align by name.

**Saved vehicle loadouts are not a driver for this, and it is worth writing
down why.** The live feature is a bookmark: all 319 `vehicle_loadouts` rows
carry a URL to a third-party calculator — `spviewer.eu` and `erkul.games` — and
**zero** have a blank one. It reads no hardpoints, resolves no components and
knows nothing about builds. The internal half,
`vehicle_loadout_hardpoints`, has never held a single row;
`create_from_defaults!` sits behind a `from_defaults` parameter nobody has ever
passed, and it seeds from `model_hardpoints`, the dead table whose game-files
rows stopped being written in 2024. So it is dead code beside a dead table, and
the honest move is deleting it rather than designing around it.

The two share the word "loadout" and nothing else. This plan stands entirely on
the loader destroying the other environment's loadouts, and needs no argument
about a future builder. What *does* point at hardpoint rows today is
`ModelPosition` — see the risks below.

**The legacy hardpoint table is dead and is not the answer.**
`model_hardpoints` (26,258 rows, 17,933 soft-deleted) carries the same
`ship_matrix`/`game_files` enum, was last written 2024-05-23 for the game-files
half, and no loader writes it. Its 6,077 `ModelHardpointLoadout` rows are
nested sub-ports, not named presets — the names are game-file port names,
`missile_01_attach` 938 times — which is what `hardpoints` now does through
`parent_type: "Hardpoint"`. So there is no curated data to preserve and the slot
identity is `hardpoints`, with no decision to make. Repointing
`vehicle_loadout_hardpoints` off the legacy table and deleting the pair is
separate and unblocked.

## Order

1. **The table and the backfill.** `hardpoint_builds` with
   `(hardpoint_id, environment, version)` unique, `BUILDS_RETAINED` and
   `retained_versions` mirroring `ComponentBuild`, and a backfill writing the
   current live build from the columns already on the row. Nothing reads it yet.

   Add a unique index on `(parent_type, parent_id, sc_name)` in the same PR.
   The slot's natural key is already unique in fact — 0 duplicates over the
   22,561 game-file rows — but nothing enforces it except
   `find_or_initialize_by` in the loader, and once a slot is the thing other
   records point at, that is not enough.
2. **Dual-write.** `persist_slot` calls `apply_build` alongside `apply`, and
   `persist_loadout` stops destroying: `retire_absent_builds(HardpointBuild,
   :hardpoint_id, …)` takes its place for the `game_files` half. This is the PR
   that makes a second load non-destructive, and it is the one item 3 is gated
   on.
3. **Move the reads.** `api/v1/hardpoints/_base.jbuilder` and everything that
   embeds it resolve facts through the build, and the nested `json.hardpoints`
   recursion filters to children the build describes.
4. **Drop the columns**, after (3) has been on `main` long enough to trust —
   and this folds into item 4 of the parent plan rather than standing alone.

## Risks

- **The fragment cache is keyed on the row that stops carrying the facts.**
  `models/hardpoints.jbuilder` caches on `["v1", hardpoint, hardpoint.component,
  Manufacturer.artwork_version]`. Once the component comes from the build, a
  build row changing under an untouched slot leaves the cached fragment stale.
  The build row has to enter the key, and the transitive walk matters more than
  a grep — an earlier pass on this codebase found 3 fragments by grep and 25 by
  walking.
- **`ModelPosition` points at a hardpoint** with `ON DELETE nullify`, and
  `model_positions.hardpoint_id` is unique per model. Slots being stable makes
  this better than it is today, but `generate_for_model!` reads group and
  category, which become build facts.
- **`Hardpoint#parent` is polymorphic across four types**, and the split has to
  hold for all of them. Measured:

  | `parent_type` | ship_matrix | game_files |
  | --- | --- | --- |
  | `Model` | 4,666 | 15,138 |
  | `Component` | — | 3,789 |
  | `Hardpoint` | 308 | 3,617 |
  | `ModelModule` | — | 17 (plus 5 with no source) |

  `Component`-parented slots are the sub-hardpoints of a hidden component — a
  door holding a cargo grid — written by `ItemsLoader`, and `Component` is the
  one parent type that already has a build table. Whether those slots hang their
  facts off `HardpointBuild` or off `ComponentBuild` is worth deciding rather
  than defaulting: uniform is simpler, but a component's ports describe the
  component, which is already per-build.

  `ModelModule` has no build table at all (parent plan, item 1's findings), so a
  module's slots have no build to resolve against until it gets one. At 22 rows
  that is a footnote, not a blocker.
- **Row count.** 22,561 game-file slots times three retained builds per
  environment is ~68k build rows per environment. Small, but the loader writes
  them all on every load, and `Hardpoint.find_each(&:save)` already runs over
  the whole table at the end of `ModelsLoader#all`.

## Verification

- A loader test that loads two environments in sequence and asserts the first
  one's loadout survives the second — the assertion that does not exist today,
  and the reason this was found by reading rather than by a test.
- The loadout fingerprint used on the first PTU load is a good shape for it:
  `parent_type:parent_id/sc_name=component_id` over `source = 1`, hashed.
- `test/loaders/sc_data/base_loader_loadout_test.rb` already characterizes
  `persist_loadout`; the cleanup change belongs there.

## What it makes possible later

Recorded as a **consequence**, not as a reason to do this. The justification is
the loader destroying the other environment's loadouts and nothing else — see
the note above about what this is not about.

Fleetyards has no loadout editor of its own; the saved "loadouts" today are
links to `spviewer.eu` and `erkul.games`. When one is built, the user's
selection is a set of `(slot → component)` pairs per vehicle, and three things
about it follow from this split:

**The slot reference.** A foreign key to the `hardpoints` row plus the
denormalised name path — at most three segments, since nesting bottoms out at
depth 3 (18,944 slots at depth 1, 2,979 at 2, 638 at 3). The key gives
integrity, the path survives a slot row being recreated. That is the same
division the catalogues already use, where the UUID is internal and the export's
key is the identity.

**A saved selection floats rather than pins.** It is "these components in these
slots", re-resolved against whichever source the reader asked for, with each
entry able to say whether its slot and its component are in that build — the
pattern #4753 established for inventory entries: the row survives the patch and
reports that it is no longer available. Pinning a loadout to the build it was
made against would be more honest historically and would take away the thing a
player actually wants after a patch, which is to see their own ship against the
new one.

**Validity is itself a build fact.** `min_size`, `max_size`, `types`,
`port_tags` and `required_tags` all move to the build row, so "does this
component fit this slot" has a different answer per source: a selection valid
under live can be invalid under PTU. The selection therefore cannot be validated
once on write — it has to be validated on read, per source. This is the part
most likely to be missed, because every other write path in the app validates
once.

**`vehicle_loadout_hardpoints` should be deleted rather than kept for this.** It
has never held a row, it is wired to the dead `model_hardpoints`, and an editor
needs fields it does not have — the name path, and a separation between a
model-level preset and a user's own selection on their own ship. Carrying an
empty table forward because a feature might want it one day is how the legacy
pair came to exist.
