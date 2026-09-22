# sc_data fixture export

A curated stand-in for `data/sc_data/parsed/<environment>`, laid out exactly
like the real parsed tree so a loader can be pointed at it with nothing but a
different `base_folder` and `sc_environment`:

```ruby
ScData::Loader::ItemsLoader.new(base_folder: Rails.root.join("test/fixtures/sc_data"))
```

`test/support/sc_data_fixture_tree.rb` wraps that up as `fixture_loader`.

## Why

A load of the real tree walks ~7,800 item files and writes ~7,300 components
with ~3,800 hardpoints — around two and a half minutes per call. The loader
tests called it once or twice each, which made `items_loader_test.rb` alone
roughly two thirds of the whole Minitest suite's CPU time.

The files here are verbatim copies of real export entries, so they carry the
real shape. Each one is present for a reason:

| File | Covers |
| --- | --- |
| `items/paint_100i_black_orange.json` | names an `icon`, and is the paint whose swatch the loader attaches |
| `items/aegs_avenger_cml_chaff.json` | names no icon — the retire-the-artwork path |
| `items/aegs_avenger_thruster_main.json` | a plain component, reused across builds |
| `items/aegs_avenger_cargogrid_stalker.json` | carries an `inventory_ref` |
| `items/inventory_aegs_avenger_cargogrid_stalker.json` | the `category: inventory` row that ref resolves to, which a load itself skips |
| `items/aegs_avenger_nose_s3.json` | carries a `loadout`, so the hardpoint pass runs |
| `equipment/behr_rifle_ballistic_01.json` | names a manufacturer_ref the manufacturers tree carries |
| `equipment/gys_helmet_03_01_01.json` | carries a volume and the box it fills |
| `manufacturers/beh.json` | Behring, the maker the rifle points at, and it names a logo |
| `icons/**/paint_100i_flame_black_orange_icon.png` | the artwork the paint names, under the `.tif` path the export writes |
| `icons/**/behring_256.png` | Behring's logo, same |

The later catalogues are curated the same way, by branch rather than by volume:

| Catalogue | Covers |
| --- | --- |
| `commodities/` | a metal, an ore, a mineral, a harvestable and an alloy for the type ladder; `hadanite` counted with a piece volume against `iron` in bulk; `slam` declared outside the commodity trees; `gold`'s SVG icon and its container sizes against `shipammo_size_1`, which has none; `gold_ore` refining into `gold`, and three construction-material forms refining into one good |
| `game_missions/` | the alignment fork (`firesale_cfp` lawful, `firesale_hh` unlawful) and an unattributed contract that must answer neither; `klescher` the one stated payout against five the game settles; a reputation loss keeping its sign; two carrying blueprint pools; one `released: false`; `huntthepolaris` the item reward that names MG Scrip |
| `manufacturers/` | `sasu` and `roo` are both Sakura Sun, which is the de-duplication; `roo` names no logo where `sasu` does, which is the load-order trap; `mxox`, `prar` and `aeg` the corrected names; `taln` the icon every artwork test attaches |
| `blueprints/` + `blueprint_pools/` | two recipes and the Foxwell pool that hands one of them out, so a load walks the source side as well as the recipe side |
| `equipment/` | a rifle and its magazine, two medical consumables, a keycard, the template that borrows a name, a helmet, an armour suit, three skins and a dev copy, and `behr_ltp_kinetic_01`, the unmeasured placeholder that has to stay blank |

`parsed/empty/` is a second environment holding nothing at all — what a build
whose files failed to sync looks like from a loader's side.

## Refreshing

Copy the file over from `data/sc_data/parsed/live` again. Nothing here is
hand-edited, so a stale copy is a copy that was never refreshed rather than
one that lost local changes.

## What these cannot catch

The export changing shape — a renamed field, a key that stopped being exported,
a payout the game started stating. A curated fixture cannot tell any of those
from a fixture nobody refreshed, so the question has to be put to the real tree.

That used to be one test per loader file, which meant every pull request pulled
a 311MB tree to ask it. A fork or Dependabot branch reads no object-storage
credentials, so those runs fell through to whatever tree the cache was keeping
and failed on an export from months ago — a bump that touched nothing would go
red on a contract assertion.

So they live in `test/contracts/` now, skipped unless the tree is on disk and run
by the `sc_data Contract` workflow, which pulls it. See
`test/support/sc_data_contract_tree.rb`. Nothing under `test/loaders/` reads the
real tree any more: if a new loader test needs it, it belongs in `test/contracts/`
rather than beside its fixtures.
