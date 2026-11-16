# Create ship modules from the game files

Working plan for #6356. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A load creates the modules and body kits the game files describe and links them to the ships whose slots take them, so a ship page lists them under the source that ships them.

## Open questions

- None

## What changed

### Phase 1: Parser
1. `ItemsParser`: body kits (`GREY_Shiv_Cosmetic_*`, `GLSN_Basher_Addon_Mohawk_*`, by a rule stronger than the key, e.g. no ports and a "Bodykit" name) get category `bodykit` instead of `module`.
2. `ModelsParser`: keep definition port types written without `subtypes` (`Hash.from_xml` drops a lone `type` attribute) and read `PortTags` / `RequiredTags` in either spelling. Done; it also restores ~30,000 port types and 161 empty editable ports across all ships.

### Phase 2: Loader, modules
1. `ItemsLoader`: add `bodykit` to the imported categories (components, as today).
2. `ModelModulesLoader`: per model, find ports that accept `Module` (types include `Module`, or no types and required tags). For each `module` item that fits (port and ship tags, size), find or create the `ModelModule` by `sc_key` (created visible, `hidden: false`) and the `ModuleHardpoint` for that slot.
3. Hornet centre slot: also create modules for the non-module items that fit it (ball turrets, rotodome, QIG), with the turret's guns on the module's own hardpoints.
4. Skip placeholder parents, `_Base` / `_Template` / `_TEMP` items, module items whose ports are all size 0 (stubs), and `_AI_` / `_PU_` / `TEMP` ship variants as the models loader does.
5. Names: key-derived fallback when the localized name is missing; never overwrite a name an admin set (needs a way to tell, e.g. only fill when blank or still the fallback).
6. `ModelModuleBuild` rows as today, so PTU-only modules stay out of live.

### Phase 3: Body kit section
1. API: `GET /models/:slug/bodykits` (OpenAPI spec + jbuilder), listing the `bodykit` components the ship's slots accept, grouped by slot.
2. Frontend: `BodykitsList` next to `ModulesList` on `pages/ships/[slug]/index.vue`, plus translations in every locale by hand.
3. Hide every ship page section that has nothing to show for the ship (paints, modules, body kits, upgrades, carried by, loaners, variants).

### Phase 4: Verify
1. Parse + load PTU locally: MPUV-1T lists the pods under the PTU source and not under live; F7C lists cargo mod, ball turret, rotodome; Shiv/Basher show body kits; Galaxy/Retaliator/Apollo/Aurora Mk II keep their curated modules without duplicates.

## Intent Verification

- [ ] **MPUV-1T page, PTU source:** lists the new pods; live source does not.
- [ ] **Hornet pages:** list every option of the centre slot.
- [ ] **Shiv / Basher pages:** body kit section lists the kits per slot.
- [ ] **Curated modules:** matched by `sc_key`, no duplicates, admin names untouched.
- [ ] **Placeholders:** `RSI_Galaxy_Module`, `AEGS_Retaliator_Module_Front`, `_Base`/`_Template` items not created.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/items_parser.rb` | item category (`module` vs `bodykit`) |
| `app/lib/sc_data/parser/models_parser.rb` | port defs; add ship tags |
| `app/lib/sc_data/loader/items_loader.rb` | imported component categories |
| `app/lib/sc_data/loader/model_modules_loader.rb` | create modules + module hardpoints |
| `app/models/module_hardpoint.rb` | slots, stock modules, `derive_slot` |
| `app/models/model_module.rb` | `in_build`, visibility |
| `app/controllers/api/v1/models_controller.rb` | `modules`; new `bodykits` |
| `app/frontend/frontend/pages/ships/[slug]/index.vue` | ship page sections |
| `app/frontend/frontend/components/Models/ModulesList/index.vue` | pattern for the body kit list |

## Discovery Log

- **2026-11-16** Local PTU load (dump + scratch tree): 15 modules created, no duplicate keys; MPUV-1T lists the three pods under ptu only; the Galaxy's keyless store "Refinery Module" takes `RSI_Galaxy_Module_Refinery` instead of a twin; Hornet Mk I/II centre bays list cargo box, turrets, VariPuck, rotodome, Ghost cap. Unnamed components stay out of the component catalogue (`Component.named`); the user is fine with ship page + loadouts only.
- **2026-11-16** Body kits are `Module` parts and fit module slots; discovery excludes the `bodykit` category, and the body kit endpoint keeps only it.
- **2026-11-16** Module slot options reuse `LoadoutSlots.sub_type_fits?` / `tags_fit?` against components, not `LoadoutSlots.options`: that one requires a name (`catalogued`) and narrows a mixed Turret+Module port to Turret once a turret is stock.
- **2026-11-16** Ship tags were not the gap: the definition XML declares module port tags and types, and the parser lost them (`type` attribute cast hint, `RequiredTags` casing).
- **2026-11-16** Initial research and plan creation. Dry run: live 43 / PTU 48 module items; only `ARGO_MPUV_1T` has an MPUV module port; Galaxy/Apollo/Retaliator-front ports carry no required tags (the modules' tags are provided by the ship).

## Progress
- [x] Phase 1: Parser
- [x] Phase 2: Loader, modules
- [x] Phase 3: Body kit section
- [x] Phase 4: Verify
