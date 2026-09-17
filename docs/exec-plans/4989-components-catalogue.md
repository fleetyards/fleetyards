# Components — a public catalogue with per-category metrics

## Goal

A public Components catalogue: 1,282 equippable components across 20 categories, each with
its own stable URL, searchable and filterable, sortable on the metrics that matter, and a
detail page that renders every figure we hold for that component's category — with every
hardpoint on every ship page linking into it.

## Status — paused, 2026-09-17

**Parked until the Blueprints catalogue (#4988) is fully shipped.** Phase 4 was always blocked
on the shared catalogue shell that #4988's D8 puts on its branch; the rest is parked with it so
the two catalogues land in one navigation rather than two.

| phase | PR | state |
|---|---|---|
| 1 — unique slug, `type_data` to `jsonb` | #5000 | **merged** |
| 2 — the public API | #5003 | open, CI green (17/17) |
| 3 — the metric renderer | #5006 | open, stacked on #5003 |
| 4 — the pages | — | not started; needs #4988's shell |
| 5 — UEX prices | — | scoped, not started |

Also shipped on the way, independent of the stack: **#5007**, the parser fix for #5002 —
`tags` was stored as the array's own inspect output for every component in the tree.

Review feedback on both open PRs has been addressed: `hardpoints` is back in the list response
(D3), the plan's D3 section now matches what shipped, and the powered-item block renders
`powerRanges`.

**Metric filters shipped.** Each of the eight metrics now takes a `Gteq` and an `Lteq` in the
public query, so "shields over 10,000 HP" is a filter rather than something a client pages
through and sifts itself — 31 of the 73 shields, against 43 in the 1,000–10,000 band. The
ransackers behind them already existed (they are what make the metric sorts work), so this was
the schema and the permit list catching up; the predicates, the sorts and the ransackers are
all generated from one map, `Component::METRICS`, so they cannot drift apart.

A component whose `type_data` lacks the key is absent from a filtered result rather than
sorted to one end — the cast is over a key it does not carry.

**Picking this back up:** #5003 and #5006 are stacked, so rebase the leaf last, and expect a
cascade of force-pushes per merge. Both will have drifted from `main`; re-run
`bin/generate-schema` **and** `bin/generate-asyncapi`, then fix the `components.parameters`
ordering by hand (see the tooling notes below). Phase 4 starts by rebasing onto whatever
#4988 built.

## Context

Resolves #4989.

Components are the largest body of game data on the site with no public surface at all. The
only way to see one today is to find a ship that happens to mount it, where a hardpoint row
renders a name, a manufacturer and a size and stops. There is no `/components/`, no detail
page, and no `show` action to build one on — `config/routes/api/components_routes.rb` is
`resources :components, only: [:index]` plus a `weapons` collection route.

Every figure below is measured against `live 4.10.0-live.12519617`, the build the local
production dump actually carries. `config/app/sc_data.yml` moved on to `4.10.1-live.12660092`
part-way through this work; no row of that build is loaded locally, so the counts describe the
older one. The shape does not move with a patch — the decisions do not depend on which.

Related: #4988 (a public Blueprints catalogue). Both issues add the first public sc_data
catalogue this site has ever had. #4988's D8 settles the shared shell; this plan consumes it
rather than re-deciding it (D7 below).

Every count in the issue body was re-measured against the local production dump. All of them
hold except three, corrected in D1, D2 and D8 — and each correction changes the work.

## Decisions

Eleven decisions were open on the issue. Five were put to the user and are recorded with what
was chosen; the rest are taken as the research settled them.

### D1 — Named, with metrics, minus the per-ship structure

**Chosen: `current_version` + `hidden = false` + name present + `type_data` present, minus the
`seat`, `controller` and `fueltanks` categories. 1,282 rows.**

One predicate, applied identically by the list and the detail page — otherwise a hardpoint
links to a component the list refuses to show.

The `type_data` predicate does the heavy lifting: it drops all 954 paints, which carry no
`type_data` and already have a surface as ship paints. What it does **not** drop — and the
issue assumed it would — is the per-ship structural furniture, which carries `type_data` and
sailed through:

| category | rows | what they are |
|---|---|---|
| `fueltanks` | 319 | `htnk_<ship>` / `qtnk_<ship>` — **every one is a per-ship internal tank**. There is no equippable fuel tank in this category at all. |
| `seat` | 269 | cockpit displays, 248 of them named "TRGT. STATUS" |
| `controller` | 226 | per-ship shield and power controllers, 139 named "SHIELDS" |

814 rows, 39% of the 2,096 the predicate alone yields, and the same rows that produce the
worst slug collisions (313 + 248 + 139 = 700 of 1,374). Excluding the three categories is a
whole-category rule, not a name heuristic — verified: no equippable member hides in any of
them.

**What ships:**

| category | rows | | category | rows |
|---|---|---|---|---|
| weapons | 303 | | thrusters | 15 |
| countermeasures | 166 | | bombcompartments | 13 |
| missile_racks | 142 | | refuel_boom | 8 |
| turret | 124 | | lifesupport | 7 |
| armor | 87 | | selfdestruct | 7 |
| powerplant | 78 | | fuel_intakes | 5 |
| cooler | 74 | | jumpdrive | 4 |
| shieldgenerator | 66 | | quantumenforcementdevice | 4 |
| radar | 61 | | module | 1 |
| utility | 59 | | **total** | **1,282** |
| quantumdrive | 58 | | | |

1,152 of the 1,282 (90%) carry a manufacturer. All 1,282 carry an `sc_key`.

**The 112 "Manned Turret" rows stay.** They are per-ship entries — the same pattern as the
three excluded categories, one layer down — but the `turret` category also holds real,
mountable turrets, so excluding it wholesale would lose them, and no per-row rule separates
them cleanly. **Decided: keep them.** They are genuinely mounted on a ship, a hardpoint link
reaches them, and a page that exists is better than a link that 404s. Worth revisiting only if
the list reads as noisy once it is on screen; it moves a constant, not the architecture.

### D2 — A real unique slug, with a migration

**Chosen: a unique slug, over `sc_key` or the UUID in the URL.**

`slug` is unusable as it stands. It has **no index at all** — not even a non-unique one
(`db/schema.rb:322-330` lists only `manufacturer_id`, `name`, `sc_key` unique, and `version`)
— and `Component` inherits the bare `ApplicationRecord#update_slugs`, which is
`self.slug = generate_slug(name)` with no disambiguation (`app/models/application_record.rb:70`).

**The issue understates this badly.** Its worst case is `pc2-dual-s4-mount` shared by six rows.
Measured against the visible current set, the real worst is **`internal-tank` shared by 313
rows**, then `trgt-status` × 248, `remote-turret` × 143, `shields` × 139, `manned-turret` × 121.
The issue's example only reproduces if you ignore `current_version` and `hidden` and look
across every component ever loaded. "Worst is 6" reads as a nuisance; "worst is 313" is a
structural collision, and it is what rules out keeping `slug` as-is.

After D1's exclusions the picture improves but does not resolve:

| | |
|---|---|
| catalogue rows | 1,282 |
| in a colliding slug group | **625 (48.8%)** across 122 slug values |
| worst remaining | `manned-turret` × 112, `joker-defcon-noise-launcher` × 48, `aegis-gladius-decoy-launcher` × 41 |
| with no `sc_key` to disambiguate with | **0** |

So `sc_key` disambiguates every catalogue row — but roughly half of all catalogue URLs will
carry a suffix, which is a fact to design the slug format around rather than discover later.

Rejected: **`sc_key` in the URL** — unique and indexed already, zero migration, but ugly
(`behr_lasercannon_s3`), worthless for search, and blank on 1,404 components. Rejected: **the
UUID** — free and total, and no public catalogue wants it.

**The migration has a trap the catalogue set hides.** A unique index is table-wide, and the
table holds 1,404 named rows with **no `sc_key`** — all of them outside the catalogue, all of
them currently colliding freely. The index must therefore either be partial, or the backfill
needs a fallback suffix for rows `sc_key` cannot disambiguate. Decide which before writing the
migration; a plain `add_index unique: true` fails on the existing data.

Reuse rather than reinvent: `Model` already carries `legacy_slug` plus
`redirect_to_canonical_slug` issuing a 301 (`app/controllers/frontend/base_controller.rb:192-198`),
which is the mechanism for keeping an old URL alive when a slug changes under a game patch.

### D3 — One payload, and no list/detail split after all

**Revised during Phase 2. What shipped is a single payload; the `extended:` flag was built,
then removed.**

The issue proposed a list payload and a detail payload, and `Model`'s `extended`-folded-into-
the-cache-key looked like the cheap way to get one. Two things killed it, in order:

1. **`availability` cannot move.** It is a `required` property, so a list omitting it breaks
   every client reading the index — and gating it saves nothing anyway, because
   `item_prices_cache_key` already loads `item_prices` for every component to build the cache
   key. Only `hardpoints` was left to gate.
2. **`hardpoints` cannot move either.** The index has always emitted it. It is optional in the
   schema, so a response without it still validates — but that documents the incompatible
   change rather than avoiding it, and a client reading `items[].hardpoints` breaks. Marking a
   field optional is not a deprecation.

With nothing left to gate, the flag was unused machinery and went with it. What remains is the
same partial for both actions, which is simpler than what was planned.

**The list is therefore no lighter than before.** That cost is real — `hardpoints` is an
association hit per component, which is why the slim `weapons` endpoint exists — but it is the
status quo, not a regression, and the fix is a lighter endpoint of its own the way `weapons`
got one. Dropping a field from an established response is not the way to get there.

The cache key still moves to `v2`: the payload gained `description` and `requiredTags`, and a
fragment cached under the old key would go on serving the shape without them.

`tags`, `ammunition`, `powerConnection` and `heatConnection` are **not** in the payload — see
the Phase 2 corrections below for why. `inventoryConsumption` is not either, because
correcting its documented type is a breaking change the tooling cannot check reliably.

### D4 — Reuse `useHardpointStats`; it is already the per-category renderer

The issue frames D4 as thirteen renderers to write from scratch. Half of them already exist.
`app/frontend/frontend/composables/useHardpointStats.ts` branches on category and emits an
ordered, labelled `HardpointStat[]` for **one** component — weapons, shieldgenerator, cooler,
powerplant, quantumdrive, jumpdrive, the four thruster categories, radar, countermeasures,
armor, fuel_intakes, and tractor beams by a `tractorBeam` flag.

Measured against D1's 20 categories: **10 are covered, 10 are not.**

Better still, its 177 `labels.hardpoint.*` keys **already exist in all seven locales** and are
genuinely translated (149 of 177 differ between `en` and `de`; the 28 that match are units and
proper nouns). This removes what the issue called "the bulk of the translation work" — see D9.

Three things it needs before a detail page can use it:

1. **A category mapping.** It keys off `HardpointCategoryEnum`, the **slot** vocabulary, not
   `Component#category`. The enum splits thrusters four ways (`main_`, `retro_`, `vtol_`,
   `maneuvering_thrusters`) and adds `external_fuel_tanks` and `emp`. A component whose own
   category is `thrusters` matches **no** branch. Without the mapping the thruster rows render
   nothing.
2. **Nine new branches.** These D1 categories have no renderer today and render nothing:

   | category | rows | | category | rows |
   |---|---|---|---|---|
   | `missile_racks` | 142 | | `lifesupport` | 7 |
   | `turret` | 124 | | `selfdestruct` | 7 |
   | `utility` | 59 | | `quantumenforcementdevice` | 4 |
   | `bombcompartments` | 13 | | `module` | 1 |
   | `refuel_boom` | 8 | | | |

   `missile_racks` and `turret` alone are 266 rows — 21% of the catalogue — so this is not a
   tail of oddities. (`fueltanks` is excluded by D1, so no `capacity` branch is needed.)
3. **The shared powered-item block.** `powerRanges`, `signatureEm`, `signatureIr`,
   `powerConsumption` and `powerMinimumFraction` are carried by every powered category and are
   rendered **nowhere today** — a grep for all five across the composable returns zero hits.
   The acceptance criteria require this block explicitly, so it is new work.

The ship-context couplings are not a problem: `quantumFuelTankSize`, `weaponPowerRatio` and
`powerPlantContextKey` are all `inject(..., undefined)` behind guards, so off a ship page the
ship-dependent figures simply drop out. Signature changes from `Hardpoint` to something a bare
component satisfies — it reads only `hp.category`, `hp.component.typeData` and
`hp.component.size`.

### D5 — `type_data` becomes `jsonb`

**Chosen: the column type changes, over promoting selected metrics to columns or shipping no
metric sort.**

Today `type_data` is `t.string` with `serialize … coder: YAML`. No SQL reaches inside it: no
ransacker, no index, no `ORDER BY damage`. `ComponentBuild::FILTERABLE` excludes every
serialised column deliberately — "nothing filters on a serialized structure". So a catalogue
that cannot answer "shields sorted by max health" is the current ceiling, and D5 is the
decision that lifts it.

`jsonb` makes every metric filterable, sortable and GIN-indexable in one migration instead of
one migration per metric. The codebase already runs 15 `jsonb` columns, including
`hull_doors`, `hull_parts` and `signature_cross_section` on `models`/`model_builds` beside
YAML-serialised neighbours — so this is a direction already taken, not a new one.

**The migration does not backfill.** `20260811130000_change_signature_cross_section_to_jsonb.rb`
is the precedent and it simply drops and re-adds:

```ruby
def up
  remove_column :models, :signature_cross_section
  add_column :models, :signature_cross_section, :jsonb
end
```

That is sound here for the same reason: `type_data` is loader-owned, and a loader run
repopulates it. It also means the change is cheap to reverse.

**Two hazards to plan around:**

- **A column drop breaks the running old release.** Pre-deploy migrates before the new
  container boots, so between the migration and the boot the old code selects a column that no
  longer exists. `type_data` is read on nearly every component query. Either the deploy takes
  a brief window deliberately, or the change lands as add-new-column → backfill → switch reads
  → drop-old across two deploys. **This is the single riskiest step in the plan** and it is
  worth the two-deploy shape.
- **Blast radius.** The column is read by the admin, the thirteen `anyOf` schemas under
  `app/api_components/shared/v1/schemas/`, and eight-plus frontend composables. Nothing should
  change behaviourally — `serialize` comes off and Rails hands back the same Hash — but every
  one needs a test pass, and `ItemsLoader` writes it in two places, including the
  `inventory_ref` path where a cargo container's `type_data` comes from a *different* item.

Alongside it, two things that need no migration at all:

- **Sorting is already built and switched off.** `Component::ALLOWED_SORTING_PARAMS` and
  `DEFAULT_SORTING_PARAMS` exist and are dead only because `components_controller.rb:38`
  overwrites `components_query_params["sorts"] = "name asc"` unconditionally. Replacing that
  with `sorting_params(Component, …)` — the helper every other controller uses — restores
  honest name and date sorting immediately.
- **The text search is one predicate.** Only `name_cont` is permitted. `description` is
  already `ransackable`, and `manufacturer` is already a ransackable association.

### D6 — Current build by default; a retired component is reachable and says so

`currentVersion` already defaults to true and the payload already carries `retired`. The
catalogue lists the current build. A component that has left the build stays **reachable** by
URL — a ship's older loadout points at it, and a dead link there is worse than a marked page —
and renders an explicit "no longer in the current build" state rather than presenting stale
figures as current.

PTU is the same question one layer out and needs no new mechanism: the source is switchable,
and every figure on these pages is relative to the selected source. The one trap already
recorded: a persisted PTU choice is inert until `sources` answers, so the page must render
against the resolved source, not the stored preference.

### D7 — It lives in #4988's shared catalogue shell

**Chosen: honour #4988's D8 and consume the shell it builds, over building it here.**

#4988's plan records that the shared public catalogue section and its nav land on *its* branch
with Blueprints as first tenant, and that #4989 rebases onto it. That decision stands.

**The cost is real and should be stated plainly:** the shell does not exist yet. Only #4988's
loader PR (#4998) is open, with three PRs behind it, and its Phase 4 is where the shell lands.
This plan's Phase 4 is therefore blocked on that, and every squash merge in that stack forces
a cascade of force-pushes down the branches below it.

Phases 1–3 here are independent and can proceed in parallel — they are backend, migration and
composable work that touches none of the shell.

Route `meta` needs both namespaces: `nav.*` labels the tab and `title.*` the document. The
detail page also wants a Rails-side route the way `get "ships/:slug"` has one, or a shared link
renders the generic card instead of the component — a `components/:slug` frontend route plus a
`Frontend::BaseController#component` action setting `@title`, `@description`, `@og_image` and
prefetching the payload.

### D8 — There are no images. The list must not pretend otherwise

**The issue is wrong about this, and it changes the design.** It reports "869 of 3,435 have an
icon" and asks the list to look deliberate at a 25% hit rate.

Measured: **all 887 components carrying an icon are `paints`** — the single category D1
excludes. Across the 1,282 rows that actually ship, there are **0 icons and 0 store images**.

So the list is not a card grid with placeholders; it is typographic and metric-led — name,
manufacturer, size, grade, class, and the one or two figures that matter for that category
(exactly what `useHardpointStats` marks `primary`). This is a better list for the data anyway:
a component is chosen on numbers, not on a picture. If component icons are rasterised later
they are additive, not load-bearing.

### D9 — Labels: much smaller than the issue estimates

The issue budgets "a label for every metric key in D4" as the bulk of the work. **That half is
already done** — 177 `labels.hardpoint.*` keys exist and are translated across all seven
locales (D4).

What is actually missing, measured from `config/locales/*/filter.yml`:

| | en | de / es / fr / it / zh-CN / zh-TW |
|---|---|---|
| `filter.component.category.items.*` | 34 | **0** |
| `filter.component.sub_type.items.*` | 3 (of ~39 live values) | **0** |
| `filter.component.class.items.*` | 5 | 5 |

The only filter vocabulary complete in all seven locales is `class` — backed by a **dead
column that matches zero current rows**. Categories are English-only; sub-types are barely
started.

Roughly 204 category strings + ~270 sub-type strings, by hand, in seven locales, with no
Crowdin in the loop. The `titleize` fallback is correct and is exactly what hides the gap —
`I18n.t("filter.component.category.items.#{item}", default: item.titleize)` renders
"Shieldgenerator" in German forever and never warns.

Public `nav.components.*` and `title.components.*` are also new: the existing keys of those
names are under the **admin** namespace.

Scope note: only the ~20 categories D1 actually ships need labels for the catalogue, not all 34.

### D10 — A history tab, on its own endpoints

`ComponentBuild` is a row per build and the admin already has a history page.
`/ships/:slug/history` is the public precedent and the shape to copy: it is a separate route
under `meta: { customTitle: true }` calling **its own** queries (`useModelChanges`,
`useModelPriceHistory`, …), each in its own `Panel` with an `Empty` fallback.

That answers the question the issue says this decision gates: **the `show` endpoint returns one
build.** History is a separate endpoint, so the detail payload stays small and the tab is
additive rather than a precondition. It lands in Phase 4 and can slip without blocking the
catalogue.

### D11 — No feature flag

**Reversed. There is no flag.**

The plan had a `components` entry in `config/feature_flags.yml` gating `show`, matching #4988's
D9. It is gone: nothing here is experimental or risky enough to earn a gate. The API is
additive — a `show` endpoint where there was none, and sorting the index already advertised —
and the pages are a new path nobody is on yet, so there is nothing to roll back to.

A flag that is never switched off is cost without benefit: an entry in the registry, a check on
every request, a 403 documented on the operation, and a switch somebody has to remember to
throw before the feature does anything.

`index` and `weapons` were never gated anyway, because both answered long before any of this.

## What changed

### Phase 1 — `type_data` to `jsonb`, and a unique slug (PR 1)

1. `type_data` → `jsonb` on `components` and `component_builds`, in the two-deploy shape D5
   describes rather than a bare drop-and-add.
2. Drop `serialize :type_data, coder: YAML` from `Component` and `ComponentBuild`.
3. Slug migration: unique index, `sc_key`-derived disambiguating suffix, backfill, and a
   fallback (or a partial index) for the 1,404 named rows with no `sc_key` — see D2's trap.
4. `update_slugs` on `Component` gains collision handling, following `StockPosition`'s
   suffixing pattern. `ItemsLoader` keeps it correct across a patch.
5. Verify the thirteen `anyOf` schemas, the admin pages and the eight-plus composables read
   an unchanged shape.

### Phase 2 — The API (PR 2)

1. `show` action + route, resolving by slug with a 301 to the canonical slug.
2. One payload for both actions, with the **cache key moved to `v2`** so the new fields
   appear (D3). The `extended:` flag was built and then removed: neither `availability` nor
   `hardpoints` can leave the list response without breaking clients.
3. New payload fields: `description`, `tags`, `required_tags`, `inventoryConsumption`,
   `ammunition`, and the power/heat/signature block.
4. Replace the hardcoded sort with `sorting_params(Component, …)`; widen the text search
   beyond `name_cont`; add metric sorts now that `jsonb` allows them.
5. **Retire the filters that match nothing.** `/filters/components/item-types` returns 26
   hardcoded values and `/filters/components/classes` returns 3, and **zero current rows carry
   either column**. Both, and the `item_type_in` / `component_class_in` index params, go — a
   filter that silently returns nothing is worse than no filter.
6. Drop `shop_commodities` from `ransackable_associations`; the association does not exist.
7. Fix `class_filters`, which does `Component.all.map(&:component_class)` — a full scan of
   8,740 rows — if anything of it survives (5).
8. Document `manufacturerSlugIn` in `ComponentQuery`; the controller permits it and the schema
   does not.
9. Hand-written schema components, `./bin/generate-schema`, orval regeneration, dev-server
   restart. No feature flag — see D11.

### Phase 3 — The metric renderer (PR 3)

1. Extract `useHardpointStats` so it takes a bare component, not a `Hardpoint` (D4).
2. The `Component#category` → stat-vocabulary mapping, without which thrusters render nothing.
3. Nine new category branches, and the shared powered-item block.
4. Unit tests per category against real `type_data` shapes.

### Phase 4 — The pages (PR 4) — **blocked on #4988's shell**

1. `/components` list in the shared section (D7): search, category and sub-type filters, sort,
   pagination, typographic rows with no imagery (D8).
2. Detail page: every metric for the category, grouped and labelled, plus manufacturer, size,
   grade, class, tags and required tags.
3. A retired component marked rather than shown as current (D6).
4. `components/:slug` Rails route + `Frontend::BaseController#component` for meta tags.
5. Every hardpoint on every ship page links to the component — the payoff link, in
   `Models/Hardpoints/BaseItem/index.vue` and its item variants.
6. The history tab (D10).
7. Category and sub-type labels in all seven locales, plus public `nav.*` / `title.*` (D9).

### Phase 5 — Component prices from UEX (PR 5)

No component has ever had a price: `Uex::PriceSyncer::ITEM_TYPE = "Model"`, and `item_prices`
carries no `Component` rows, so `availability` is two empty arrays on every component in the
payload. UEX does carry them.

**Measured against `https://api.uexcorp.uk/2.0/items_prices_all`:**

| | |
|---|---|
| price rows | 24,138 |
| distinct items / terminals | 2,827 / 471 |
| catalogue components priced by exact name | 545 |
| …by `sc_ref` → UEX `item_uuid` | 348 |
| **…by either** | **551 of 1,282 (43%)** |

Coverage is uneven by category:

| category | priced | of | | category | priced | of |
|---|---|---|---|---|---|---|
| weapons | 196 | 303 | | countermeasures | **0** | 166 |
| missile_racks | 62 | 142 | | turret | **0** | 124 |
| cooler | 50 | 74 | | armor | **0** | 87 |
| powerplant | 42 | 78 | | shieldgenerator | 41 | 66 |

**43% is not a 57% failure, and the phase must not be scoped as though it were.** Plenty of
items are only crafted or looted and are sold at no terminal at all, so no price is the
*correct* answer for them. The three zeroes read that way: a per-ship turret is not a shop
item, and armour is largely looted or crafted.

So the number that decides this phase is not the matcher's ceiling on its own. It is the split
between:

- **matched** — UEX has a price and we found it;
- **legitimately unpriced** — nothing sells it, so there is nothing to find;
- **missed** — UEX has a price under a name our matcher did not recognise.

Only the third is work. The unmatched UEX *names* skew to ship-specific mounts ("Anvil Hornet
F7C Nose Turret") and internal codes ("SW16BR1"), which suggests the third bucket is the
smallest of the three.

**Blueprints can measure the second bucket.** #4998 is merged, so `Blueprint` and its
polymorphic `craftable` are on `main`: once the loader has run, "how many unpriced components
are craftable" is a query rather than a guess. That is the first thing to run, and it is also a
genuine payoff between the two catalogues — a component page that says *"not sold; crafted from
this blueprint"* is better than one that shows an empty price panel.

**The shape is already proven twice over.** `ItemPrice#item` is polymorphic, so no migration is
needed to hang a price off a `Component`; and `Uex::CommodityPriceSyncer` (114 lines, with
`CommodityMatcher` and `CommodityMapper`) is the second item type this codebase already syncs.
Phase 5 mirrors it rather than generalising `PriceSyncer`, whose vehicle-specific rental
handling has nothing to say here.

1. Measure the three buckets first, not just the matcher — load blueprints locally, then count
   how many unpriced components are craftable, and sample what is left. Try normalised names,
   manufacturer-qualified names and `id_category` against the remainder. The size of the
   *missed* bucket decides whether this is one PR or three.
2. `Uex::Client#item_prices` over `items_prices_all`. Note `/items` **cannot** be fetched
   wholesale — it answers 400 without `id_category`, `id_company` or `uuid` — but
   `items_prices_all` carries `item_name` and `item_uuid` inline, which is what matching needs.
3. `Uex::ComponentMatcher` and `Uex::ComponentPriceSyncer`, against the commodity pair.
4. The snapshot/repricing path from `Uex::PriceSnapshot`, so a repriced component reads apart
   from an admin having typed the figure in by hand.
5. **The page must distinguish "nothing sells this" from "we have no price yet."** An empty
   panel reads as missing data on a component that is working as intended; the crafted ones
   should say so, and link to the blueprint once Phase 4 of #4988 gives them a page.
6. Scheduling alongside the existing syncers.

**Consequence for D3.** `availability` is two empty arrays today, which is part of why keeping
it in the list payload costs nothing. Once it carries real rows across 471 terminals the list
gets genuinely heavier, and the slim list endpoint deferred in D3 becomes worth building.

## Intent Verification

- [ ] **List** — `/components/` lists 1,282 components, paginated, with a text search and filters that all match rows
- [ ] **No dead filters** — `item-types` and `classes` are gone; every offered filter can match something
- [ ] **Honest sorting** — sorting covers the whole result set, metrics included, not one page of it
- [ ] **Stable URLs** — every component the list shows has its own page at a unique slug, and an old slug 301s
- [ ] **Every metric** — the detail page renders every figure for that component's category, grouped and labelled, including the power/heat/signature block
- [ ] **Identity** — manufacturer, size, grade, class, tags and required tags shown where present
- [ ] **Retired** — a component out of the current build is marked, not presented as current
- [ ] **The payoff link** — every hardpoint on every ship page links to the component's page
- [ ] **Seven locales** — category, sub-type and nav/title labels exist in all seven
- [x] **API** — a documented `show`, and a regenerated schema. The list payload is *not* distinct from the detail one: the issue asked for a split, and neither field that would have moved can leave the index without breaking clients (D3).
- [ ] **Prices** (Phase 5) — components carry UEX prices where a terminal sells them, and a component nothing sells says so rather than showing an empty panel

## Key files

| File | Role |
|------|------|
| `app/models/component.rb` | `with_facts`, ransackers, the dead sorting constants, `item_types`, the facet helpers |
| `app/models/component_build.rb` | `FACTS`, `READ_THROUGH`, `FILTERABLE` — the build-fact contract |
| `app/models/application_record.rb:70` | `generate_slug(name)`, no disambiguation — D2's root cause |
| `app/controllers/api/v1/components_controller.rb:38` | The hardcoded sort that makes `ALLOWED_SORTING_PARAMS` dead |
| `app/controllers/api/v1/filters/components_controller.rb` | The four filter endpoints; two must go |
| `app/views/api/v1/components/_component.jbuilder` | The cache key that hides any new field |
| `app/lib/sc_data/loader/items_loader.rb:214` | The 32-category `hidden` allowlist; also writes `type_data` twice |
| `app/api_components/shared/v1/schemas/component*.rb` | The thirteen `anyOf` `type_data` shapes |
| `app/frontend/frontend/composables/useHardpointStats.ts` | The existing per-category renderer (D4) |
| `app/frontend/translations/*/labels.json` | 177 metric labels, already in seven locales |
| `config/locales/*/filter.yml` | Category/sub-type labels — English-only (D9) |
| `app/frontend/frontend/components/Models/Hardpoints/BaseItem/index.vue` | Where the hardpoint link goes |
| `config/routes/frontend_routes.rb:16` | `ships/:slug` — the meta-tag route to mirror |
| `db/migrate/20260811130000_change_signature_cross_section_to_jsonb.rb` | The drop-and-re-add precedent (D5) |

## Not in scope (deferred)

- **Prices** — **promoted to Phase 5 above**, not deferred any more. UEX carries 24,138 item price rows and 43% of the catalogue matches on a naive exact name; the shape is the commodity syncer's.
- **Paints.** Excluded by D1 and already surfaced as ship paints. Listing them again under a second vocabulary is a deliberate non-goal.
- **Component icons.** 0 of the catalogue set has one (D8), and component icons are vectors that are not rasterised the way other attachments are.
- **The 112 "Manned Turret" rows.** Flagged in D1; a constant to revisit once the list is visible.
- **The loader's `hidden` allowlist.** Untouched. The public predicate is narrower and independent, so a game patch adding a category still needs a human either way.
- **`item_type` / `component_class` columns.** The public filters go (Phase 2); dropping the columns themselves is a separate cleanup, and the admin still reads them.

## Discovery Log

- **2026-09-17** Issue read, branch and worktree created. D1, D2, D5 and D7 resolved with the user; D1 refined a second time after measurement.
- **2026-09-17** Re-measured every count in the issue against the local production dump at `live 4.10.0-live.12519617`. 8,740 / 7,274 / 5,936 / 3,435 / 2,096 / 954 paints / 3,598 mounted / 0 prices all confirmed exactly.
- **2026-09-17** **D2 correction.** The issue's worst slug collision (`pc2-dual-s4-mount` × 6) only reproduces ignoring `current_version` and `hidden`. The real worst on the visible set is `internal-tank` × 313, then 248, 143, 139, 121 — a structural collision, not a nuisance.
- **2026-09-17** **D1 correction.** The `type_data` predicate drops all 954 paints but **not** the per-ship structure: 319 fuel tanks, 269 seats, 226 controllers survive it, 39% of the set and 700 of the 1,374 colliding rows. Verified every `fueltanks` row is a per-ship `htnk_`/`qtnk_` tank — the exclusion is a whole-category rule, not a heuristic. Final set 1,282.
- **2026-09-17** **D8 correction.** All 887 icon-carrying components are `paints`. The catalogue set has **0 icons and 0 store images** — the list cannot be image-led at all, against the issue's assumed 25%.
- **2026-09-17** **D4 measured.** `useHardpointStats` already renders 10 of D1's 20 categories, and its 177 labels are already translated in all seven locales — so the issue's "bulk of the translation work" is done. But the other 10 render nothing, and two of them (`missile_racks` 142, `turret` 124) are 21% of the catalogue. Also needed: a `Component#category` → `HardpointCategoryEnum` mapping, without which thrusters match no branch, and the powered-item block, which a grep for all five of its keys shows is rendered nowhere.
- **2026-09-17** **D3 reversed.** `Model`'s `extended`-in-the-cache-key looked like a cheap list/detail split, and it was built — then removed. `availability` is a required property and `hardpoints` has always been in the index, so neither can leave a list response without breaking clients; marking a field optional documents that change rather than avoiding it. One payload for both actions, which is simpler than the plan.
- **2026-09-17** **D5 halved.** Metric sorting needs `jsonb`, but name/date sorting needs only deleting one line — `ALLOWED_SORTING_PARAMS` exists and is dead because the controller overwrites `sorts`.
- **2026-09-17** Confirmed #4988 has built no frontend yet (loader PR only), so the shell D7 depends on is three PRs away.
- **2026-09-17** **Phase 1 built and verified against a copy of the real rows.** Slug backfill 0.43s, jsonb conversion 2.3s; 5,692 named rows produce 5,692 distinct slugs with 3,048 NULLs, and neither table loses a `type_data` row (5,538 and 13,628 preserved). `down` converts back, so the pair round-trips.
- **2026-09-17** **A quarter of `type_data` was already unreadable.** 4,556 of 13,628 `component_builds` rows hold a Ruby `Hash#inspect` string rather than YAML, so they have never deserialized — all of them in `4.9.0-live.12344265`, the backfilled build, and none in `components`, which is 100% valid YAML. The migration converts both formats (the inspect one needs `" => "` → `": "` and Ruby `nil` → `null`, which covers all 4,556) and raises on anything else rather than writing NULL over a component's metrics. **Whatever wrote those rows is still unfixed** — see below.
- **2026-09-17** **jsonb needs a wrapping type, not a bare column.** The YAML carried `!ruby/hash:ActiveSupport::HashWithIndifferentAccess` tags, so readers have always had symbol access; `Hardpoint#thruster_class` digs `:thruster_class` and a bare Hash would answer `nil` without raising. `Types::IndifferentJson` keeps the column's new type invisible to its readers.
- **2026-09-17** Confirmed the payoff directly: `ORDER BY (type_data ->> 'max_health')::numeric` over shields now runs, which is the query D5 exists for.

- **2026-09-17** **Two review findings, both real.** A slug was re-derived on every save, so the arrival of a second "Manned Turret" moved the incumbent's URL to the suffixed form on its next import — against the stability the suffix exists to give, with no `legacy_slug` to redirect the old one. Reproduced, fixed, and covered. The fix is deliberately *not* `will_save_change_to_name?`: `name` reads through to the build, which `apply_build` writes after the row, so a rename lands one save late and self-heals on the next — gating on the column's own change would freeze the stale slug for good. A test catches that.
- **2026-09-17** **`jsonb` silently re-enabled build comparison on `type_data`.** `BuildCompare.diffable_facts` excludes a fact by asking whether its type is `ActiveRecord::Type::Serialized`; `jsonb` is `Type::Json`, so the comparer began reporting the 420 rows whose metrics differ between two builds — exactly what that exclusion exists to prevent. Caught by CI, not locally. Excluded by name (`STRUCTURE_FACTS`) rather than by type, because a blanket `Type::Json` exclusion would also drop `EquipmentBuild#volume_dimensions`, which is compared today and worth reading.
- **2026-09-17** The concurrent slug race (check-then-write) is left to the unique index and documented at the callback: the loser raises `RecordNotUnique` rather than taking another row's URL. A uniqueness validation would run *before* `before_save` and so check the stale slug — making it correct means moving derivation to `before_validation` for Component alone, and still would not close the race.

### Why 4,556 rows were never readable — closed

`db/data/20260827150100_backfill_component_builds.rb` seeds a build row per component with
`build.update!(FACTS.index_with { |fact| component.public_send(fact) })`. It shipped in #4557
(`3bf683f3e`); `ComponentBuild` only gained `serialize :type_data, coder: YAML` in #4559
(`ed660b600`). So the backfill assigned a real Hash to a plain string column with no
serializer attached, and Ruby wrote `to_s` — the `Hash#inspect` format. Every later load wrote
proper YAML, which is why the damage stops at `4.9.0-live.12344265` and never touches
`components`.

**No live write path is affected**, and the migration converts the residue rather than leaving
it. Nothing to fix beyond what Phase 1 already does.

### Phase 2 corrections, found while building it

Three of Phase 2's planned steps were wrong as written, and the code said so:

1. **Neither `availability` nor `hardpoints` can move behind `extended`.** `availability` is
   a `required` property, and gating it saves nothing because `item_prices_cache_key` already
   loads `item_prices` for every component. `hardpoints` is optional in the schema but has
   always been emitted by the index, so removing it breaks a client reading
   `items[].hardpoints` — optional is not deprecated. The flag went with them (D3).
2. **The two dead filter endpoints are deprecated, not removed.** `oasdiff` confirms removing
   a public path is `api-path-removed-without-deprecation`. Their query params stay permitted
   as well: dropping a param does not error, it silently stops filtering, so a client asking
   for nothing would suddenly receive everything. The catalogue simply will not offer them.
3. **`tags` is held back from the payload.** The parser double-encodes it for every component
   in the tree — `["[\"flightReady\"]"]`, 4,000 of 4,000 sampled — so publishing it would
   ship visibly broken values. Filed as **#5002**; `required_tags` is clean and ships.

Also learned: **ransack ignores a non-whitelisted attribute in silence.** The metric
ransackers looked right and did nothing — a `max_health_gteq` filter returned all 8,740 rows
and the sort produced no `ORDER BY` — until the names were added to `ransackable_attributes`.
Only running it against real data showed it.

And `size` is not offered as a sort: the column is a string holding `"10"` and `"12"` beside
`"M"` and `"S"`, so ordering it puts 10 and 12 ahead of 2.

### Phase 3 corrections

The plan said nine categories needed a new renderer. Measured against the build, three do:

| | categories | rows |
|---|---|---|
| Carry **no** metric keys at all | `missile_racks`, `turret`, `bombcompartments`, `lifesupport`, `module` | 301 |
| Already rendered | `refuel_boom` — by a *shape* check after the category chain, like tractor beams, which is why its labels already existed | 10 |
| Genuinely new | `utility`, `selfdestruct`, `quantumenforcementdevice` | 83 |

So 301 rows have a detail page carrying the power block and nothing else. That is the honest
answer for them, not a bug — but it is what makes the shared power/signature block
load-bearing rather than decorative.

Two traps found building it:

- **`selfdestruct` stores its figures as strings** (`"15000"`, `"45"`), so a
  `typeof === "number"` guard — which every other branch uses — silently skips all seven rows.
- **The category mapping is not optional.** A thruster component says `thrusters`; the slot
  vocabulary only has `main_`/`retro_`/`vtol_`/`maneuvering_thrusters`. Unmapped it matches no
  branch and renders nothing.

The power block hangs off `useComponentStats` rather than `useHardpointStats`, so a ship's
hardpoint list is unchanged by any of this.

### Schema tooling, the hard way

Three separate causes behind `api-schema-breaking` and `api-schema-check` failing, worth
recording because none was the obvious one:

1. **oasdiff is non-deterministic on a deeply nested shared component.** Six identical runs of
   the admin check gave 14 errors four times and 0 twice — it attributes the change to a
   different path each run, so no fixed ignore list can match. The fix was to stop making the
   breaking change: `inventoryConsumption` was documented as a `string` that no endpoint has
   ever emitted, so correcting its type bought nothing and cost a flaky gate.
2. **macOS and Linux order `components.parameters` differently.** `bin/generate-schema` emits
   it before `securitySchemes` locally and after it on CI, so `api-schema-check` fails on pure
   ordering. Regenerating locally flips it back every time.
3. **The AsyncAPI cable documents embed the same `Component` schema** and have their own
   generator. `api-schema-check` runs `bin/generate-asyncapi` and diffs those files too.

### #5002 is not fixed by #5001

Checked once #5001 landed: it swaps `translate` for `localize_name` on `name` and `short_name`
only. The `tags` extraction is untouched and the parsed tree still holds `tags: ["[]"]`.
`tags`, `ammunition`, `powerConnection` and `heatConnection` stay out of the payload.

## Progress

**Paused after Phase 3 — see Status above.**

- [x] Phase 1 — `type_data` to `jsonb`, and a unique slug (PR 1)
- [x] Phase 2 — The API (PR 2)
- [x] Phase 3 — The metric renderer (PR 3)
- [ ] Phase 4 — The pages (PR 4) — **parked** until #4988 ships its shell
- [ ] Phase 5 — Component prices from UEX (PR 5)
