# Commodities — a public catalogue with prices and a price history

## Goal

A public Commodities catalogue at `/catalogue/commodities`: 232 commodities, searchable,
filterable by type and by whether anything trades them, sortable — including on price — and a
page per commodity saying what it is, where it is bought and sold, what it has been worth over
the last 90 days, and which recipes consume it.

## Context

Resolves #5026.

Commodities are the third tenant of the catalogue section #4989 built, after components (#5003,
#5015, #5021) and blueprints (#4988). They are the one body of sc_data we hold that already
carries prices and a price history, and their only surface today is a picker inside the
logistics ledger. There is no `/catalogue/commodities`, no detail page, and no `show` endpoint.

Figures are measured against the local production dump (`live 4.10.0-live.12519617`) and, where
the dump is stale, against the live API on 2026-09-21.

### What the data says

| | |
|---|---|
| rows | 232 — and 232 in production, so the catalogue is whole |
| in the served build | 232; **nothing is retired today** |
| with a description | 191 |
| with a `uex_id` | 185 |
| with a store image | **63 (27%)** |
| `item_prices` (Commodity) | 2,595 across **124 of 232**, over **135 distinct `location` strings** |
| price snapshots | 41,509 across **16 distinct days** (2026-09-05 → 09-20) |
| `blueprint_cost_options` | **0 locally** — blueprints are in production (1,607) but absent from the dump |

Four columns the dump reports as empty — `container_sizes`, `piece_volume`, `consumable`,
`counted`, `refines_into_id` — are **filled in production** (`containerSizes` comes back as
`[0.01, 1, 2, 4, 8, 16, 24, 32]` on the live API). The dump predates the loader that writes
them. Measure these against the live API, not against `psql`.

## Decisions

### D1 — Rows, not cards. The 27% is not the reason; the images are.

The issue left this open at 63/232. Two measurements close it.

**The images are inventory icons, not artwork.** `Dymantium`'s store image is
`inv_icon_dymantium.svg`, 9,499 bytes of SVG. These are the sc_data glyphs
[[sc-data-svg-rasterization]] keeps as vectors — a leading glyph at 32–48px, with nothing to
show at card-hero size.

**Coverage is not scattered, it is categorical.** `manmade` 0/23, `nonmetals` 0/5,
`medical_supply` 0/3, `consumer_goods` 2/20, `natural` 11/48. A card grid filtered to `manmade`
is twenty-three placeholders and no pictures — not a grid with holes in it, a grid that is the
placeholder.

So: `RowList` + a `CommodityRow` whose leading glyph is the store image where there is one and a
type icon where there is not, exactly as `ComponentRow` leads with `ComponentCategoryIcon`.
Both sibling tenants already render rows, and [[row-list-hover-language]] governs the hover.

Cheap to overturn: the row is one component and `FilteredList` does not care what fills its
default slot.

### D2 — Price is a sort *and* a filter, because the ransackers already exist.

`ItemPriceConcern` (`app/models/concerns/item_price_concern.rb`) already defines `buy_price` and
`sell_price` as **scalar-subquery ransackers** with `type: :decimal`, and
`Commodity.ransackable_attributes` already includes them via
`ItemPriceConcern::RANSACKABLE_ATTRIBUTES`. The concern's own comment explains the subquery keeps
one row per item precisely so a range filter needs no `distinct` fighting the ordering.

So the aggregate the issue worried about is already written and already indexed. The cost is four
entries in `Commodity::ALLOWED_SORTING_PARAMS` (`buyPrice asc/desc`, `sellPrice asc/desc`) and the
`Gteq`/`Lteq` query properties, mirroring what #5020 did for the component metrics.

A commodity with no price sorts to the end rather than being dropped — `MIN()` over no rows is
`NULL`, and Postgres sorts `NULL` last ascending. That is the right answer here and needs a test
saying so, because it is the opposite of #4989's metric-filter behaviour (absent from a *filtered*
result).

### D3 — Terminals and the chart. Nothing computed, because nothing can be.

`item_prices.location` is free text — 135 distinct strings like
`TDD - Trade and Development Division - Area 18`. `location_url` is null throughout. There is **no
`stations` table, and no Station, Shop or Terminal model anywhere in `app/models`**. There are no
coordinates and no distances.

So a route planner is not a thing we are declining to build; it is a thing the data cannot
support. The page shows what a terminal pays and charges, grouped per location, plus the chart.
`ItemPriceConcern#sold_at` / `#bought_at` already dedupe to the cheapest row per location.

### D4 — Filters: name, type, has-a-price, price range.

`buyPriceNotNull` is a free predicate on the existing ransacker and splits the catalogue 124/108.
That 108 is D6's other half: a commodity with no price must read as *nothing we know of trades
this*, not as a broken panel.

### D5 — `filter.commodity.commodity_type.items.*` in all seven locales.

Confirmed absent from every locale: `grep` over `config/locales/*/filter.yml` finds only an
unrelated `commodity: Commodities` label. `Commodity.type_filters` falls through to
`item.titleize` for all 15 types, and `Api::BaseController#set_locale` reads `Accept-Language`, so
every non-English client reads them in English today. #5075 did exactly this repair for the
component facets — same shape, 15 values × 7 locales. [[translate-every-locale-by-hand]] applies:
there is no Crowdin round-trip that will fill these in.

### D6 — Retired, and the three different silences.

Nothing is retired today, so this cannot be tested against real data — it needs a factory build.
`#5097` already settled the shape for components and the copy generalises:

- retired → *prices are not tracked for this*, because the UEX sync only ever looks at the build
  the catalogue is on, so silence there is not evidence
- current, unpriced, consumed by a recipe → *nothing trades it; it is crafted*
- current, unpriced, no recipe → *nothing we know of trades this*

The row and the masthead mark retired with `Chip :state="ChipStatesEnum.EXCLUDED"`, as
`ComponentRow` does.

### D7 — The shared `Chart` cannot render this. Extend it rather than importing Highcharts twice.

`app/frontend/shared/components/Chart/index.vue` accepts `PieChartStats | BarChartStats`
(label/count/tooltip) and builds exactly **one** series. The price history is six nullable series
— sold and bought × lowest/average/highest.

A second Highcharts import path is the wrong fix: [[highcharts-esm-umd-dual-instance]] — the core
and accessibility imports must come from the same build or the a11y module attaches to a second
instance. So `Chart` grows a multi-series input alongside its existing one, and the commodity page
feeds it. Assertions per [[highcharts-render-assertions]].

**The chart is 16 days long, not 90.** `item_price_snapshots` starts 2026-09-05. The window stays
90 days; the axis is simply short until the syncer accumulates, and the page must not read as
broken for it.

### D8 — Add `buyPrice`/`sellPrice` to the payload; leave `availability` in the index alone.

The index **already ships every price row**: `_base.jbuilder` renders `availability.boughtAt` and
`.soldAt` for every record. A live page of 60 is **194,487 bytes carrying 539 price rows**, against
31 KB with `availability` and `storeImage` stripped.

Removing it from the index is a breaking change, and `Admin::V1::Schemas::Commodity` **inherits**
`V1::Schemas::Commodity`, so the removal would land in the admin oasdiff run too
([[api-schema-breaking-stacked-prs]]). Not this issue.

Instead the row reads two new scalars — `buyPrice` and `sellPrice`, already rendered by the *admin*
`_base.jbuilder` — rather than reducing 539 rows client-side. That is additive, it is what the row
and the sort both need, and it leaves a later issue free to decide whether the list still needs
`availability`.

### D9 — The blueprint reverse link is already shipped. It is a link, not an endpoint.

`Blueprint.consuming_commodity(slugs, …)` exists (`app/models/blueprint.rb`) and is wired through
`BlueprintFiltersConcern` to `q[consumingCommodity]` / `q[consumingCommodityIn]`, documented in
`blueprint_query.rb`. The AC is satisfied by a `useBlueprintsQuery` on the detail page with
`{ q: { consumingCommodity: slug } }` — the same shape the component page already uses for
`craftableIdEq`.

It cannot be verified against the dump (`blueprint_cost_options` is empty locally); the test needs
factories.

## What changed

### Phase 1 — The API: a `show`, a sort that works, and two price scalars

1. `CommoditiesController#index`: replace `commodities_query_params["sorts"] = "name asc"` with
   `normalize_sort_params` + `sorting_params(Commodity, …)`, per #5003's exact idiom.
2. Permit `:s, :sorts, sorts: []`, the price predicates and `buy_price_not_null`.
3. `Commodity::ALLOWED_SORTING_PARAMS` gains `buyPrice`/`sellPrice` asc+desc.
4. `CommoditiesController#show` — `find_by!(slug:)`, added to `skip_verify_authorized`;
   `only: %i[index show]` in `config/routes/api/commodities_routes.rb`.
5. `app/views/api/v1/commodities/show.jbuilder` rendering the existing `_commodity` partial.
6. `_base.jbuilder` gains `buy_price` / `sell_price`; **bump `_commodity.jbuilder`'s `"v1"` cache
   prefix** — a cached fragment is a rendered payload, so the new fields are invisible on every
   commodity already served until the key moves.
7. `V1::Schemas::Commodity` gains the two properties; `queries/commodity_query.rb` gains `s`/`sorts`
   via a new `V1::Schemas::Enums::CommoditySortingEnum` (the Blueprint pattern, not Component's
   inline enum — it avoids two anonymous generated TS types). Remember the admin schema subclasses
   the public one.
8. `bin/generate-schema` then `bin/generate-clients`. Needs a server restart first
   ([[generate-schema-needs-server-restart]]), and the schema is generated *from the integration
   tests*, so the tests come before the regeneration, not after.

### Phase 2 — Locales

9. `filter.commodity.commodity_type.items.*` — 15 values × 7 locales.

### Phase 3 — The list page

10. `pages/commodities.vue`, `pages/commodities/routes.ts`, `pages/commodities/index.vue`.
11. `components/Commodities/{Row,List,FilterForm}/index.vue`, `composables/useCommodityFilters.ts`,
    `useCommoditySortFields.ts`.
12. Append the tenant to `CATALOGUE_TENANTS` and delete its "still to come" line. The nav, the
    `/catalogue/` entry and the route table all follow from the list; `routes.spec.ts` asserts every
    route the router draws is claimed by a tenant, so a missed `detailRoutes` entry fails there.

### Phase 4 — The detail page

13. `pages/commodities/[slug].vue` — identity, description, type, the price panel, the terminals,
    the chart, the recipes that consume it, and the retired marker.
14. Generalise `Components/Availability` to take `availability` + `retired` rather than a
    `Component`, so both tenants render one panel.
15. Extend `Chart` with the multi-series input (D7).
16. `config/routes/frontend_routes.rb`: `get "catalogue/commodities/:slug", to: "base#commodity"`,
    plus `Frontend::BaseController#commodity` for the meta tags — with `@og_image` from
    `store_image`, which components could not set. **No legacy redirect**: there was never a public
    `/commodities` page.
17. Page strings in all seven locales.

## Intent Verification

- [ ] **`GET /api/v1/commodities/:slug`** returns a commodity by slug and 404s otherwise, documented
      in `swagger/v1/schema.yaml`
- [ ] **The index honours `q[s]` and `q[sorts]`** — a test applying every entry in
      `ALLOWED_SORTING_PARAMS` and asserting `desc == asc.reverse`, the loop that catches a sort
      silently dropped for a missing ransackable attribute
- [ ] **An unpriced commodity sorts last on `buyPrice asc`** rather than vanishing
- [ ] **`/catalogue/commodities`** lists 232 with search, type filter, has-a-price filter, sort and
      pagination
- [ ] **A commodity page** shows type, description, the terminals that buy and sell it, and the
      price chart
- [ ] **An unpriced commodity says which silence it is** — retired / crafted-only / untraded
- [ ] **A retired commodity is marked**, against a factory build, since nothing is retired in the data
- [ ] **The recipes that consume it** are listed, via `q[consumingCommodity]`
- [ ] **`catalogue/commodities/:slug`** is route-recognised and serves meta tags
      ([[ruby-tests-cannot-render-frontend-pages]] — assert recognition, not rendering)
- [ ] **Commodities is in the catalogue nav** and `routes.spec.ts` is green
- [ ] **15 type labels × 7 locales**, and every page string in seven

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/commodities_controller.rb` | the hardcoded sort (L15), and where `show` goes |
| `app/models/commodity.rb` | `ALLOWED_SORTING_PARAMS` (L229), `type_filters` (L265), `refined_from` (L206, rendered nowhere) |
| `app/models/concerns/item_price_concern.rb` | the `buy_price`/`sell_price` ransackers D2 rests on |
| `app/views/api/v1/commodities/_base.jbuilder` | the payload; `_commodity.jbuilder` holds the cache prefix |
| `app/api_components/v1/schemas/commodity.rb` | hand-written; the admin schema subclasses it |
| `app/frontend/frontend/pages/catalogue/tenants.ts` | one list drives the nav, the entry and the routes |
| `app/frontend/frontend/pages/components/index.vue` | the list page to mirror |
| `app/frontend/frontend/components/Components/Availability/index.vue` | the price panel to generalise |
| `app/frontend/shared/components/Chart/index.vue` | single-series today (D7) |
| `test/integration/api/v1/components_show_test.rb` | the `show` + 404 DSL to clone |

## Not in scope (deferred)

- **Dropping `availability` from the index payload** — breaking, and it propagates into the admin
  schema (D8). Its own issue.
- **Any trade routing, distance or profit calculation** — the data has no locations (D3).
- **`refined_from`** — the model has the association and nothing renders it. A small follow-up;
  the refining chain is one hop and the dump cannot show it.
- **`uex_id` / `uex_code` in the public payload** — admin-only today, and no page needs them.

## Discovery Log

- **2026-09-21** Built, in five commits. Two decisions moved while writing it. **D7 grew**: the
  shared `Chart` needed the multi-series mode before the page could use it, so it and the
  `Availability` lift became a refactor commit of their own. **D2 got cheaper still** — the
  index's `s` enum is schema-enforced, so an unknown sort is rejected at validation rather than
  falling back; the fallback test that assumed otherwise was dropped rather than documenting a
  400 the components index does not document either.
- **2026-09-21** Research and plan. Corrected four things the issue assumed:
  the blueprint reverse link is already shipped as a `Blueprint` scope and a documented query
  param (D9); `buy_price`/`sell_price` ransackers already exist, so price sorting is nearly free
  (D2); the store images are 9.5 KB SVG icons and absent from whole categories, which closes D1;
  and the index already ships 194 KB per page of 60 because `availability` is in the list payload
  (D8). Two new constraints: the shared `Chart` is single-series (D7) and the snapshot table holds
  16 days, not 90.

## Closing

One PR, per `size/M`. The four phases are commits inside it, and **the PR body carries
`Closes #5026`** — so merging the last phase closes the issue and moves it off the board.

If the work is ever split across PRs, only the one carrying Phase 4 may use a closing keyword;
the earlier ones reference `#5026` without one. A tenant is not done until its pages exist —
`CATALOGUE_TENANTS` is the list that says so, and it is not appended until Phase 3.

## Progress
- [x] Phase 1 — the API
- [x] Phase 2 — locales
- [x] Phase 3 — the list page
- [x] Phase 4 — the detail page, and `Closes #5026`
