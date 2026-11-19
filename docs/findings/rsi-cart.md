# RSI Cart

**Date:** 2026-11-18
**Status:** Reference; the Sync extension's `addToCart` action and the buy list's cart buttons are built on it

How RSI's pledge store puts a ship, an upgrade or a buy-back into the cart. It was captured from a signed-in session by adding items through RSI's own pages, then checked by sending the same calls directly. Read this before changing the extension's cart code, or when adding to the cart starts failing after an RSI site update.

## Authentication

Every call carries the session cookie and the `X-Rsi-Token` header. The cart calls also need `X-CSRF-TOKEN`, taken from `<meta name="csrf-token" content="…">`. That tag is in the server-rendered HTML of any store page (`/en/store/pledge/cart`, `/pledge`), so one GET of the cart page provides it. Without the header, a `/graphql` mutation fails with `ErrValidationFailed` and `details: {csrfToken: "Required"}`.

## Calls

| What | Calls | Ids |
|---|---|---|
| Store SKU (standalone ship) | `POST /graphql` `AddCartMultiItemMutation`, variables `{storeFront: "pledge", query: [{skuId, qty}]}` | Standalone SKU id |
| Upgrade from the store | 1. `POST /api/ship-upgrades/setContextToken` `{fromShipId, toShipId, toSkuId, pledgeId: null}`<br>2. `POST /pledge-store/api/upgrade/v2/graphql` `mutation addToCart($from: Int!, $to: Int!) { addToCart(from:, to:) { jwt } }`, where `from` is the ship id and `to` is the target's **upgrade SKU**<br>3. `POST /api/store/v2/cart/token` `{jwt}` | `models.rsi_id`, `models.rsi_upgrade_sku_id` |
| Upgrade bought back | The same three steps with `pledgeId` set in step 1. RSI then signs `mode: "buyback"` and the pledge into the JWT. | `buyback_pledges.rsi_pledge_id`, `upgrade_from_ship_id`, `upgrade_to_ship_id`, `upgrade_to_sku_id` |
| Ship, package or item bought back | `POST /api/store/buyBackPledge` `{id}` | `buyback_pledges.rsi_pledge_id` |

The JWT from step 2 expires 30 seconds after it is issued. Its payload names the SKU, the from ship, the price in cents and the mode (`browse` or `buyback`).

`ClearCartMutation` (`mutation { store(name: "pledge") { cart { mutations { clear } } } }`, with the CSRF header) empties the cart. Use it to clean up after a probe.

## Cart rules

- Standalone ships and any number of store upgrades share one cart.
- **A buy-back has to be alone.** Adding one replaces whatever the cart held. Adding anything next to it fails with `TyCartValidationException` and `details.skus` reading "Cannot acquire more than 1 item at once with a Pledge Buy-Back".

## Refusals

| Case | Answer |
|---|---|
| Unknown or off-sale SKU | GraphQL error `TyCartValidationException`, message "Invalid cart", `details: null` |
| Upgrade pair not sold | GraphQL error "Upgrade not available. Upgrade from ship X to ship sku Y is not available." |
| Buy-back gone or invalid | `{success: 0, code: "ErrBuyBackPledge", msg: "Invalid Buy-Back Pledge"}` |
| Buy-back next to other items | GraphQL error `TyCartValidationException`, `details.skus` as above |

All of these come back with HTTP 200.

## Store SKUs

The `GetShip` search that `Rsi::PledgeStoreLoader` runs returns, per ship:

- `upgrades[]`: the upgrade SKUs into the ship that are on sale. `upgrades[0].id` is the `to` of an upgrade (13053 for the Crucible), and the same SKU appears in `skus` too.
- `skus[]`: the upgrade SKU, the standalone versions, packages and packs mixed together. All have the subtitle "Pledge". A second search by slug, which needs no sign-in, gives the store category:

  ```graphql
  query GetSkus($query: SearchQuery) { store(name: "pledge") { search(query: $query) { resources { id subtitle ... on TySku { isWarbond } } } } }
  # variables: {query: {skus: {slugs: [...]}}}
  ```

  There, `subtitle` is "Standalone Ships", "Package", "Packs" or "Ship Upgrade". A warbond SKU cannot be paid for with store credit, so the loader prefers a regular one.

Search one chassis per request: with several `chassisId`s in one search, RSI gives every ship the first ship's `skus`.
