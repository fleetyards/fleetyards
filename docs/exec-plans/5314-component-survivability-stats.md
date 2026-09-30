# Component stats: mass, self-repair, distortion and health for every component

Working plan for #5314. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every component carries its health, mass, damage multipliers, self-repair and distortion from the game files, the API documents them, and the component detail page shows them in a shared block.

## What changed

### Phase 1 — Parser and loader
1. `ItemsParser#extract_durability` fills `durability` with health, mass, resistances, self_repair and distortion.
2. `ItemsLoader` writes `durability` (it never did), so the component and its build carry it.

### Phase 2 — API
1. `ComponentDurability` (+ nested repair, distortion, resistances components) on `Component.durability`.
2. `_base.jbuilder` renders it.

### Phase 3 — Frontend
1. A shared `ComponentDurabilityStats` block on the component detail page: Physical / Self-repair / Distortion.
2. Labels in all 7 locales.

## Intent Verification
- [ ] ARCC Torrent: health 410, mass 630, repair 56 s to 20 %, max 1; distortion 3500 / 2625 / 233 per s / 3 s
- [ ] Nothing shows for a component without the data

## Key files
| File | Role |
|------|------|
| `app/lib/sc_data/parser/items_parser.rb` | reads the blocks |
| `app/lib/sc_data/loader/items_loader.rb` | writes `durability` |
| `app/api_components/shared/v1/schemas/component_durability*.rb` | schema |
| `app/frontend/frontend/components/Components/…` | detail block |

## Discovery Log
- **2026-09-30** Coverage on 4.10.1-live: mass 5281, health/resistances 4005, self-repair 3787, distortion 1027 of 7798 items. A re-parse changes only `durability`.

## Progress
- [x] Phase 1
- [ ] Phase 2
- [ ] Phase 3
