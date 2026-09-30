# Mining and salvage: laser, module and salvage modifier stats

Working plan for #5317. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Mining lasers, mining modules and salvage modifiers carry and show their stats.

## What changed

### Phase 1 — Parser
1. Mining laser `type_data.mining`: fracture power min/max, extraction power, optimal/max range, charge up/down, module slots, modifiers
2. Mining module `type_data`: activation, charges, duration, fracture/extraction power change, modifiers (incl. FLTR filter)
3. Salvage modifier `type_data`: salvage speed, radius, extraction efficiency multipliers

### Phase 2 — API
Named components: `ComponentMiningLaser`, `ComponentMiningModifiers`, `ComponentMiningModule`, `ComponentSalvageModifier`, activation enum.

### Phase 3 — UI
`useHardpointStats`: mining laser rows replace the DPS figures; module and salvage modifier rows under utility.

## Intent Verification
- [ ] Arbor MH1 reads 117–2,340 fracture, 1,850 extraction, 60/180 m, 1 slot, instability −35 %, resistance +25 %, window +40 %, inert −30 %
- [ ] Surge reads +50 % fracture, 15 s × 7, instability +10 %, resistance −15.5 %
- [ ] FLTR Mk1 reads inert −20 %, extraction −15 %

## Key files
| File | Role |
|------|------|
| `app/lib/sc_data/parser/items_parser.rb` | parsing |
| `app/api_components/shared/v1/schemas/component_mining_*.rb` | schema |
| `app/frontend/frontend/composables/useHardpointStats.ts` | rows |

## Not in scope (deferred)
- **Salvage head beam stats** — the head's own salvage defaults are all 1×; its reach is already shown as the tractor range.

## Progress
- [x] Phase 1
- [ ] Phase 2
- [ ] Phase 3
