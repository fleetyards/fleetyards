# Read combat and tool stats for FPS gear from the game files

Working plan for #6149. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every FPS weapon, attachment, tool, throwable, mine, mining gadget and consumable carries the stats the game files hold for it, from parse through API to the equipment page.

## What changed

### Phase 1 — Parser
1. Move the mining-modifier extraction out of `ItemsParser` into a shared module so gadgets reuse it.
2. `ScData::Parser::GearStats` builds a `stats` hash per record: fire modes (Sequence, Parallel and DynamicCondition resolved), ammo, magazine, regen, heat, melee, attachment modifier, tool actions, explosion, mine trigger, mining, consumable effects.
3. `EquipmentParser` loads the lookups it needs (ammo params, magazines, consumable types, melee configs) and writes `stats`, `alpha_damage` and `dps`.

### Phase 2 — Storage
1. Migration: `stats` jsonb, `alpha_damage` and `dps` decimals on `equipment` and `equipment_builds`; schema.rb by hand.
2. `EquipmentBuild::FACTS` / `FILTERABLE`, Equipment ransackers and sort metrics, loader params.

### Phase 3 — API
1. jbuilder fields, hand-written components for every nested object, `bin/generate-schema`.

### Phase 4 — Frontend
1. Stats on the equipment page: one card per fire mode, ammo, heat, tool actions, explosion, effects, modifiers.
2. Alpha and DPS in the stats card and as sort options; translations in all seven locales.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/gear_stats.rb` | Reads the stats from one record |
| `app/lib/sc_data/parser/equipment_parser.rb` | Lookups and wiring |
| `app/lib/sc_data/loader/equipment_loader.rb` | Writes the new columns |
| `app/models/equipment_build.rb`, `app/models/equipment.rb` | Facts, filters, sorting |
| `app/views/api/v1/equipment/_base.jbuilder` | Payload |
| `app/api_components/v1/schemas/equipment/` | Schema components |
| `app/frontend/frontend/pages/equipment/[slug].vue` | Detail page |

## Discovery Log

- **2026-11-03** Equipment has no build change history (only models and components do), so that acceptance criterion was dropped from the issue.
- **2026-11-03** A charged mode's `maxChargeModifier.damageMultiplier` is a plain factor (the railgun's 20 × 300); a non-zero `pellets` overrides the pellet count at full charge.
- **2026-11-03** A Sequence entry's `delay` with `unit=RPM` is the effective fire rate; its inner action carries pellets and spread.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [ ] After merge: re-parse and push live and ptu, then check the equipment pages on main
