# Shopping cart for catalogue items: plan a buying trip

Working plan for #6001. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A signed-in user (flag `shopping_cart`) can put commodities, components and equipment in a server-side cart with quantities, and the cart page shows the aUEC total and where to buy each line, grouped by place.

## Open questions
- None.

## Design

- **One table, no cart parent.** `cart_items`: uuid id, `user_id` (fk, `dependent: :destroy` on User), polymorphic `item` (`item_type` restricted to `InventoryLedgerEntry::ITEM_TYPES`), `quantity` (integer > 0), unique on `[user_id, item_type, item_id]`, cap per user like `HangarPlanSlot::MAX_PER_PLAN`. Adding an item that is already in the cart increments its quantity. Optional `item_price_id` (fk, `on_delete: :nullify`) pins the line to one of the item's `sell` prices; a pin whose price row disappeared falls back to the cheapest.
- **Auth.** Doorkeeper `hangar:read` / `hangar:write`, like the Hangar Planner. Page at `/cart`, nav footer entry with a count.
- **Price direction.** The user pays a shop's `sell` price: best price = `sold_at.first`, never `buy` and never `rental`.
- **Place of a price.** `shop.location`, else `terminal.location`, else the raw `item_prices.location` string. Commodities are terminal-only (704 sell rows, 0 with a shop); equipment has 339 of 19,291 sell rows without a shop.
- **`GET /cart`** returns lines (item link, quantity, best unit price, line total, `unavailable: true` when nobody sells it), `groups` (place → lines, subtotal, ordered by system then place name), and totals (aUEC total, count of unavailable lines). Computed in a service object (`Carts::TripPlan`), not cached; prices preloaded with `ItemPrice::SHOP_LINK` + terminal location, guarded by a query-count test.

## What changed

### Phase 1 — Flag, model, API
1. `config/feature_flags.yml`: `shopping_cart` entry; `bin/feature-flags sync`.
2. Migration + `CartItem` model + `User has_many :cart_items, dependent: :destroy`; item-exists validation copied from `FleetContractItem#referenced_item_exists`.
3. `CartItemPolicy` (copy `HangarPlanPolicy`), `ShoppingCartFeatureConcern` (copy `HangarPlannerFeatureConcern`).
4. Controllers: `Api::V1::CartsController#show`/`#destroy` (clear), `Api::V1::CartItemsController#create`/`#update`/`#destroy`; routes file `config/routes/api/cart_routes.rb` drawn from `v1_routes.rb`.
5. `Carts::TripPlan` service + jbuilder views.
6. API components: `CartItemCreateInput`, `CartItemUpdateInput`, `Cart`, `CartLine`, `CartGroup`, `CartTotals`; reuse `InventoryItemTypeEnum`, `ItemPrice`, `ShopLink`, `LocationLink`.
7. Factories (`cart_items`; `item_prices` traits with a shop and with a terminal), model test, integration tests (incl. 403 with the flag off, 404 for another user's item), query-count test.
8. `bin/generate-schema`.

### Phase 2 — Frontend
1. `pages/cart/index.vue` + route (`needsAuthentication`, `feature: FeatureFlagName.SHOPPING_CART`), nav entries desktop + mobile.
2. `components/Cart/AddToCart` (copy `Blueprints/AddToHangar`: signed-out warning, quantity input) in the `#actions` slot of the Commodities/Components/Equipment rows and next to `<Availability>` on the three detail pages; shop stock rows (`Shops/ItemRow`) if it fits.
3. Cart page: `StatsPanel` totals, groups by place with shop/location links (borrow from `AvailabilityModal`), quantity edit, remove, clear; unavailable lines in their own flagged section. Cache updates via `setQueryData` like `useHangarPlanCache`.
4. `translations/<locale>/cart.json` + nav/title keys in all 7 locales, by hand.
5. Vitest for AddToCart and the cart page; Playwright scenario + spec for add → cart → total.

## Intent Verification

- [ ] **Add from list and detail** — a commodity, a component and an equipment item each land in the cart from their list row and detail page; adding again increases the quantity
- [ ] **Server-side** — the cart survives a reload and a second browser session for the same user
- [ ] **Prices** — each line shows the cheapest `sell` price, the line total, and the cart total matches the sum (checked against the live dump)
- [ ] **Trip grouping** — lines appear under their place; commodity lines group by terminal location
- [ ] **Unavailable** — an item with no `sell` price is flagged and excluded from the total, and the total says so
- [ ] **Remove / clear** — both work and persist
- [ ] **Flag** — API returns 403 and the route and buttons are hidden with `shopping_cart` off
- [ ] **Schema** — integration tests generate the cart endpoints in `swagger/v1/schema.yaml`

## Key files

| File | Role |
|------|------|
| `app/models/concerns/item_price_concern.rb` | `sold_at`, best price helpers |
| `app/models/item_price.rb`, `shop.rb`, `terminal.rb`, `location.rb` | Price and place data |
| `app/models/hangar_plan_slot.rb`, `fleet_contract_item.rb` | Patterns: quantity/cap, polymorphic item validation |
| `app/controllers/api/v1/hangar_plan_slots_controller.rb` | Controller pattern |
| `app/controllers/concerns/hangar_planner_feature_concern.rb` | Flag gate pattern |
| `app/policies/hangar_plan_policy.rb` | Policy pattern |
| `config/feature_flags.yml` | Flag registry |
| `test/integration/api/v1/hangar_plan_slots_test.rb`, `list_endpoint_query_counts_test.rb` | Test patterns |
| `app/frontend/frontend/components/Blueprints/AddToHangar/index.vue` | Add-button pattern |
| `app/frontend/frontend/components/AvailabilityModal/index.vue` | Per-place rendering |
| `app/frontend/frontend/components/{Commodities,Components,Equipment}/Row/index.vue` | List rows (`#actions` slot) |

## Not in scope (deferred)
- **Stop-minimising route** — set cover across shops; the per-line cheapest place answers the first question. Becomes its own issue before the PR merges.
- **Guest cart merged on sign-in** — rejected for now in the issue.
- **Sharing a cart / named lists** — rejected for now in the issue.
- **Live updates across tabs (cable)** — the Hangar Planner broadcasts nothing either.
- **Ships (`Model` prices)** — not a catalogue item here; ships are pledged/bought in other flows.

## Discovery Log

- **2026-10-26** Initial research and plan creation. Live dump: sell rows — Component 4465 (all with a shop), Equipment 19,291 (18,952 with a shop), Commodity 704 (all terminal, none with a shop).

## Progress
- [ ] Phase 1 — Flag, model, API
- [ ] Phase 2 — Frontend
