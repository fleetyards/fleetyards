# Items Missing

Working plan for #5784. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Mining gadgets, flair, carryable props, food and drink, and portable containers become Equipment rows the inventory and contract pickers can find. The ship ore pods become findable as what they are.

## What changed

### Phase 1: Equipment parser reads the carried folders
1. `CARRIED_PATHS`: `weapons/devices` becomes `mining_gadget` and `flair` becomes `flair`. `carryables/{1h,2h,tractorbeamonly}` are typed record by record:
   - Food and Drink, or anything with consumable params, become `sustenance`.
   - `InventoryContainer` and `Container` become `container`.
   - Anything with a `Flair*` SubType or `_flair_` in its key becomes `flair`.
   - FPS_Consumable and RemovableChip go through the consumable mapping. Hacking chips become `cryptokey`.
   - Cargo crates are skipped.
   - Everything else becomes `carryable`.
2. Skipped: records that name a commodity (`items_commodities_*`), and the `CARRIED_NOISE` keys (mission items, datapads, templates, lootable props, mining bases).
3. `PICKED_RECORDS` (flares, tool cases) now matches by key across every carried folder.
4. `mark_skins` groups carried props by type instead of key prefix, because their keys name no maker.
5. Volume is read from `SStandardCargoUnit` and `SCentiCargoUnit` as well as `SMicroCargoUnit`.

### Phase 2: Types, labels, pickers
1. `Equipment::EQUIPMENT_TYPES` gains `mining_gadget flair carryable container sustenance`.
2. Labels in all 7 `activerecord.yml` files, plus the `cryptokey` and `mining_gadget` item types.
3. Regenerated the schema and clients. Added an icon per new type.
4. Inventory and contract pickers:
   - The equipment category adds `mining_gadget` and `container`.
   - The consumable category picks from `sustenance` and `medical`.
   - The other category picks from `carryable` and `flair`.

### Phase 3: Ore pods
1. `ItemsLoader` files utility `Container` components as `ore_pods` and hides the `_template` and `_collapsed` rows.
2. `Hardpoint#set_group` treats `ore_pods` like `utility`, so a collapsed pod's slot keeps its group.
3. The component picker labels an ore pod by its capacity in SCU (`capacity`, or `storage` on the ROC pods).

## Intent Verification

- [x] **Mining gadgets**: all six are parsed as `mining_gadget` (contract test).
- [x] **Furniture/flair**: 195 flair records are parsed: models, plants, figures, display cases, posters and coins.
- [x] **Carryables**: 153 records are parsed: plushies, chess pieces, trophies, medals. Duplicates across key prefixes collapse, and no hand-held commodity is listed twice (contract test).
- [x] **Containers**: the Stor*All and Salvaged Skull 1–8 SCU containers are parsed with their volume.
- [x] **Mining bags**: ore pods load into `ore_pods` with no template rows (loader test), and the picker shows their capacity (spec).
- [ ] **Bucket**: the re-parsed live tree is pushed (`bin/scdata push live`) before merge.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/equipment_parser.rb` | Carried folders and their typing |
| `app/lib/sc_data/loader/items_loader.rb` | Ore pod category |
| `app/models/equipment.rb` | `EQUIPMENT_TYPES` |
| `app/frontend/frontend/components/Logistics/ComponentPicker/index.vue` | Ore pod capacity label |

## Not in scope (deferred)

- **Search aliases** ("mining bag" → ore pod). The game calls them Ore Pods, and they now sit in a category of that name.
- **Suit items** (`suit/`: mobiGlas, thruster packs). Nobody asked for them, so they stay out of this PR.

## Discovery Log

- **2026-10-18** Initial research and plan.
- **2026-10-18** Five player cryptokeys (Tigersclaw, icePick, FUNT, Ripper, Re-Authorizer) and 12 comp-boards sit in `carryables/1h`. They were missing too, and now load as `hacking_tool`.
- **2026-10-18** Existing parsed equipment files are byte-identical after the re-parse. Only new files were added (5024 → 5633).

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Push the parsed tree
