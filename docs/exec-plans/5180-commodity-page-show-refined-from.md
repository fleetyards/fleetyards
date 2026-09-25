# Commodity page: show what a commodity is refined from

Working plan for #5180. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A refined good's page lists the raw forms that refine into it, next to "Refines into".

## Open questions
- None.

## What changed

### Phase 1 — API
1. `CommodityRef` becomes a non-null object so it can be an array item; `refinesInto` moves to a `NullableCommodityRef` subclass (an `anyOf` with null reads as breaking to oasdiff).
2. `refinedFrom` (array of `CommodityRef`, optional) on the commodity schema, emitted by `show.jbuilder` only — outside the `_commodity` cache fragment, whose key only covers the commodity itself, not rows pointing at it.
3. Sources limited to the current build and ordered by name; preloaded in the show action.
4. Integration test in `commodities_show_test.rb`.

### Phase 2 — Page
1. A "Refined from" row in the identity card on `pages/commodities/[slug].vue`, one link per source.
2. `labels.commodity.refinedFrom` in all 7 locales.

## Intent Verification

- [ ] **Commodity detail API carries `refinedFrom` (slug + name)**
- [ ] **The commodity page lists them next to "Refines into"**
- [ ] **Label translated in every locale**
- [ ] api-schema-breaking stays green (oasdiff against main)

## Key files

| File | Role |
|------|------|
| `app/api_components/shared/v1/schemas/commodity_ref.rb` | The shared link shape |
| `app/api_components/v1/schemas/commodity.rb` | Public commodity schema (admin subclasses it) |
| `app/views/api/v1/commodities/show.jbuilder` | Detail payload |
| `app/controllers/api/v1/commodities_controller.rb` | Preloads |
| `app/frontend/frontend/pages/commodities/[slug].vue` | The page |
| `test/integration/api/v1/commodities_show_test.rb` | API test |

## Not in scope (deferred)
- None.

## Discovery Log

- **2026-09-25** Initial research and plan creation. `refinesInto` sits inside the `_commodity` cache fragment keyed on the commodity row, so a reverse association there would go stale when a raw form's target changes.

## Progress
- [x] Phase 1
- [x] Phase 2
