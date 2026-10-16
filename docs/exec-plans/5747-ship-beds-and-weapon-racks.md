# Show a ship's beds and weapon racks from the game files

Working plan for #5747. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The ship page and the API show a ship's beds (by berth) and its weapon-rack slots (type, sub-types, size range, required tags) read from the game files; locker counts are stored and served nowhere public.

## Open questions
- None.

## What changed

### Phase 1 — Parser
1. Move the GUID/class-name entity index pattern (`blueprints_parser.rb:339-370`) into `base_parser.rb`, or add a small class-name → record index over `entities/scitem/usables` and `entities/scitem/ships/usableitems` (bed records live in both; five bed classes only in the latter).
2. `ModelsParser` reads `derived/shiprooms.json` `vehicles` (missing file → no interior keys, as `ItemsParser#ship_room_items` does).
3. Per vehicle, from each room's `classes`:
   - beds: per bed class, berths = distinct `$anchor_bed`, `$anchor_bed_top`, `$anchor_bed_left`, `$anchor_bed_right` names (ignore `_tv*`); sum × count.
   - weapon racks: per rack class, its `SItemPortDef`s → `{types, sub_types, min_size, max_size, required_tags}`; keep every port type (WeaponPersonal, Misc, Cargo).
   - lockers: count of `locker` contents.
4. Write `interior: {beds:, weapon_racks: [{key, count, slots: [...]}], lockers:}` into the parsed model JSON; omit keys that are zero/empty so old interiors stay blank.
5. Parser tests in `test/parsers/sc_data/models_parser_test.rb` (bunk = 2, double = 2, single = 1, `_tv` ignored, rack with Cargo/Misc ports, required tags, no rooms file, vehicle with empty rooms).

### Phase 2 — Storage and loader
1. Migration: `beds` (integer), `weapon_racks` (string, YAML), `lockers` (integer) on `models` and `model_builds` (template: `20261015170000_add_storage_containers_to_models.rb`).
2. `ModelBuild::FACTS` + `serialize :weapon_racks, coder: YAML` on both `ModelBuild` and `Model`; `weapon_racks` into `STRUCTURED_FACTS`; new facts into `LATE_FACTS`; paper_trail `only:` list.
3. `ModelsLoader#update_interior` following `update_storage_containers` (write when present, clear when a build drops it, never write for a ship that never had it).
4. Loader tests next to the storage-container ones in `models_loader_test.rb`.

### Phase 3 — API
1. Integration test first in `test/integration/api/v1/models_show_test.rb`.
2. `api/v1/models/_base.jbuilder`: `beds` and `weapon_racks` (no lockers); admin jbuilder serves lockers too.
3. Schemas: new `WeaponRack`/`WeaponRackSlot` shared components, `beds` on the model schema; admin model schema gets `lockers`.
4. Bump cache keys: `api/v1/models/_model` v5, `vehicles/_vehicle` v8, admin `_model` v4.
5. Regenerate `swagger/v1`, `swagger/admin/v1`, `asyncapi/cable/v1` and the orval client; oasdiff ignores if needed.

### Phase 4 — Frontend
1. Beds tile in `components/Models/BaseMetrics` beside crew (hidden when nil).
2. Weapon-rack card in the Hardpoints metric cards, modelled on `components/Models/StorageContainers` (MetricsCard + grouping); visual-test page entry.
3. Labels in all seven locales by hand.
4. Specs beside the components.

### Phase 5 — Reworked records
1. Check `sc_key` for the Constellation family (and other ships with a `_GS` twin) against production.
2. Data migration setting `sc_key` where a model still resolves to the legacy record.

## Intent Verification

- [ ] **Andromeda GS** parses to 4 beds and 4 racks of 3 slots each (rifle 2–2, pistol 1–1, gadget 0–1)
- [ ] **Mk V Centaurus** parses to 4 beds, 5 lockers, its 19-slot rack among its racks
- [ ] **Ironclad** racks keep their `Misc/Small` and `Cargo/Box` slots
- [ ] **Clipper** multitool slots carry `required_tags: ["multitool"]`
- [ ] **Freelancer** (legacy interior) has no interior keys and the page shows nothing
- [ ] Public API serves no `lockers`
- [ ] `test/contracts` green against a re-parsed live tree

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/models_parser.rb` | reads shiprooms `vehicles`, writes interior into model JSON |
| `app/lib/sc_data/parser/base_parser.rb` | shared entity-record index |
| `app/lib/sc_data/parser/items_parser.rb` | existing shiprooms reader (modules' medical beds) |
| `app/lib/sc_data/loader/models_loader.rb` | writes the new facts |
| `app/models/model.rb`, `app/models/model_build.rb` | facts, serialize, paper_trail |
| `app/views/api/v1/models/_base.jbuilder` | public API |
| `app/api_components/shared/v1/schemas/` | schema components |
| `app/frontend/frontend/components/Models/BaseMetrics/index.vue` | beds tile |
| `app/frontend/frontend/components/Models/StorageContainers/index.vue` | template for the rack card |

## Not in scope (deferred)
- **Jump seats / crew stations** — too noisy in this export (see issue).
- **Showing lockers** — once usable in game; only a frontend change.

## Discovery Log

- **2026-10-16** Bed anchors are `helperName` attributes on alignment slots, not `Name`. Medical beds are `Bed_*` classes too; told apart by `MedBedComponentParams`.
- **2026-10-16** Production already loads the `_GS` Constellation records (mass and hull health match `rsi_constellation_*_gs`), so no `sc_key` migration.
- **2026-10-16** Scratch parse of 4.10.2-live: 1153 models, 515 with an interior — 487 with beds, 257 with racks, 53 with lockers.
- **2026-10-16** Initial research and plan. Only 4.10.2-live.12913470 has `derived/shiprooms.json` on disk; PTU trees parsed from older raw builds will get no interior keys until re-synced. A parser change needs a re-parse + `bin/scdata push` in the same PR.

## Progress
- [x] Phase 1 — Parser
- [x] Phase 2 — Storage and loader
- [x] Phase 3 — API
- [x] Phase 4 — Frontend
- [x] Phase 5 — Reworked records (nothing to change)
- [ ] Re-parse live + push, `test/contracts` against it
