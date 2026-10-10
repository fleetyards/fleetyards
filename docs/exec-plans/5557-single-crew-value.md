# One crew value per ship

Working plan for #5557. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A ship carries one crew figure: the game's `crewSize` for the build in force, else the matrix or an admin value on the column. `min_crew`/`max_crew` leave the model, the API and the UI.

## What changed

### Phase 1 — Data
1. `models.crew`, `models.rsi_crew`, `model_builds.crew`; backfill `crew = COALESCE(max_crew, min_crew)`, `rsi_crew = COALESCE(rsi_max_crew, rsi_min_crew)`.
2. `crew` joins `ModelBuild::FACTS` and `FILTERABLE`; the four old columns go to `ignored_columns` (dropped in a later release).
3. Models loader writes `crew` from the export's `crewSize`; the gap fill drops `min_crew`.
4. RSI loader writes `rsi_crew`/`crew` (max, else min).

### Phase 2 — API
1. Public model: `crew: {value, label}`; hangar/fleet stats totals become one crew total.
2. Admin model schema and input: `crew`.
3. Sorts and filters: `crew`.
4. oasdiff ignore entries, schema regen, client regen.

### Phase 3 — Frontend, Discord, translations
1. Every `crew.min`/`crew.max`/`minCrew`/`maxCrew` reader.
2. Discord ship/compare commands.
3. Labels in all seven locales.

## Intent Verification
- [ ] A ship page shows one crew figure
- [ ] An in-game ship's crew follows its build; a concept ship's follows the matrix
- [ ] Mission and event ship requirements match against the single figure
- [ ] Hangar and fleet stats show one crew total

## Not in scope (deferred)
- **Dropping the four old columns** — needs a release after `ignored_columns` ships.

## Discovery Log
- **2026-10-11** Matrix gives min = max on 228 of 254 ships; on 213 of 214 comparable ones that value equals the game's `crewSize`. Ranges survive only on concept ships.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
