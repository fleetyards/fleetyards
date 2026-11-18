# Add the hangar planner's buy list to the RSI cart

Working plan for #6409. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A buy-list row, or a whole group, goes into the user's RSI cart through the Sync extension, and the buy list says per item what RSI accepted or refused.

## What changed

### Phase 1 — SKU data
1. `models.rsi_standalone_sku_id`, `models.rsi_upgrade_sku_id`.
2. `Rsi::PledgeStoreLoader` keeps `upgrades[0].id` and, through a slug search over `skus`, the "Standalone Ships" SKU (non-warbond first). It keeps the stored value when RSI omits one.

### Phase 2 — Cart items on the buy list
1. `HangarPlans::Summary::Purchase#cart_items`, one per unit that can go into the cart: `sku`, `upgrade` (store CCU or upgrade buy-back) or `buyback`.
2. `HangarPlanCartItem` component plus a kind enum. Empty on a shared plan, since buy-back pledge ids are private.

### Phase 3 — Extension (`fleetyards-sync`)
1. An `addToCart` action: reads the CSRF token from the cart page, then adds each item and returns a result per item with an error code.
2. Advertised in `health`.

### Phase 4 — Buy list UI
1. `FleetyardsSyncAction.ADD_TO_CART` and a `useRsiCart` composable.
2. Per-row button, "add all" on the ship and CCU groups, a warning on buy-backs, per-item results and a link to the RSI cart. Locales in every language.

### Phase 5 — Findings
`docs/findings/rsi-cart.md`.

## Intent Verification

- [ ] **Store items** — a standalone ship and a store CCU from the buy list land in the RSI cart.
- [ ] **Buy-backs** — a ship buy-back and an upgrade buy-back land in the cart, with the warning shown beforehand.
- [ ] **Failures** — a refused item says why, in the user's language.
- [ ] **Old extension** — without `addToCart` in `health`, no button shows.

## Key files

| File | Role |
|------|------|
| `app/lib/rsi/pledge_store_loader.rb` | Store import |
| `app/lib/hangar_plans/summary.rb` | Buy-list lines |
| `app/views/api/v1/hangar_plans/summary.jbuilder` | Summary JSON |
| `app/frontend/frontend/components/Hangar/Planner/BuyList/index.vue` | Buy list |
| `~/dev/fleetyards-sync/lib/message-handler.ts`, `lib/rsi.ts` | Extension |

## Discovery Log

- **2026-11-18** RSI calls inspected in a signed-in session (see the issue). The CSRF meta tag is in the server-rendered HTML of `/en/store/pledge/cart`.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
