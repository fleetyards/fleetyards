# SC Data: Missing Jumpseats on Dropships

**Date:** 2026-04-25
**Status:** Open finding

## Problem

Jumpseats (troop/passenger seats) on dropships and other ships are missing from the parsed SC data. For example, the Valkyrie should have ~20 troop jumpseats but only shows 1 pilot seat.

## Root Cause

Jumpseats in StarCitizen are **environment-placed usable entities**, not ship loadout items. They work like any furniture prop in CryEngine (a bar stool, a bench at a space station):

- They have `SActorUsableParams` with a "Sit" interaction and `Type="Usable"` (not `Type="Seat"`)
- A level designer places N instances at bone positions in the ship's prefab
- The ship entity's `SEntityComponentDefaultLoadoutParams` has **no reference** to them
- They are siblings in the level hierarchy, not children in the loadout/component system

### Data location

- Raw usable files: `data/sc_data/raw/*/Data/Libs/Foundry/Records/entities/scitem/usables/`
- Naming pattern: `seat_jump_*` or `seat_chair*jump*`
- These files define the jumpseat **type** (geometry, interactions, animations) but NOT the count per ship

### Why the parser doesn't find them

1. `ItemsParser` only scans `entities/scitem/{ships,vehicles}/#{category}` — the `usables` folder is not included
2. Even if `usables` were scanned, there is no link from the ship entity to these jumpseats in the entity data
3. The per-ship count is determined by how many instances are placed in the ship's 3D prefab/level — that data is NOT part of the Foundry Records XML export

### Affected ships

Found these jump seat usable entities in the raw 4.7.1 data:

| Ship | Usable entity file(s) |
|---|---|
| Anvil Valkyrie | `seat_jump_anvl_valkyrie`, `seat_chair_template_anvl_valkyrie_jump_seat` |
| Esperia Prowler | `seat_jump_espr_prowler` |
| Drake Cutlass Black | `seat_jump_drak_cutlass_black`, `seat_jump_drak_cutlass_black_new` |
| Drake Cutlass Steel | `seat_chair_anim_drak_cutlass_steel_jumpseat` |
| Drake Cutter | `seat_jump_drak_cutter` |
| Aegis Redeemer | `seat_jump_aegs_redeemer` |
| Aegis Vanguard Hoplite | `seat_jump_vanguard_hoplite`, `seat_jump_aegs_vanguard` |
| Anvil Terrapin (medic) | `seat_jump_anvl_terrapin_medic` |
| MISC Starfarer | `seat_chair_misc_starfarer_jump` |
| Origin 890 Jump | `seat_chair_890jump_*` (crew, dining, suite, escaperaft) |

### Note on `crewSize`

The `crewSize` field in the ship entity XML only counts **operational crew** (e.g., Valkyrie `crewSize="1"` = pilot only). It does not include passenger/troop capacity.

## Possible Solutions

1. **Manual mapping** — Maintain a lookup table of ship -> jumpseat count. Simplest and most reliable since the data isn't machine-extractable from the current export.
2. **Parse usables by naming convention** — Scan `usables` for `seat_jump_*` files and associate with ships by name. Only tells us the jumpseat type exists, not the count per ship.
3. **External data source** — Cross-reference with ship specs from RSI website or community databases that track passenger capacity.
