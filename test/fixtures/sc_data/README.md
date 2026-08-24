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

`parsed/empty/` is a second environment holding nothing at all — what a build
whose files failed to sync looks like from a loader's side.

## Refreshing

Copy the file over from `data/sc_data/parsed/live` again. Nothing here is
hand-edited, so a stale copy is a copy that was never refreshed rather than
one that lost local changes.

What the fixtures cannot catch is the export changing shape — a renamed field,
a key that stopped being exported. Each loader test file keeps one test
pointed at the real tree for that.
