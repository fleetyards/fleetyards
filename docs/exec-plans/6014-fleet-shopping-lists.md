# Fleet and squadron shopping lists

Working plan for #6014. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Fleets keep shared shopping lists, optionally restricted to squadrons. They are published from an authorised member's own cart list, and members copy them back into their own carts.

## Open questions
- None.

## What changed

### Phase 1 — Backend model and privileges
1. Migration: `fleet_shopping_lists` (fleet, name, description, visibility, created_by) and `fleet_shopping_list_items` (polymorphic item, quantity), with item unique per list.
2. `FleetShoppingList` (`SquadronRestrictable`, privileges, `visible_to?`) and `FleetShoppingListItem`, which answers `item_price_id` as nil so `Carts::TripPlan` can price it.
3. `FleetRole::PRIVILEGE_GROUPS` + presets, `FleetMembership::CAPABILITY_PRIVILEGES`, and a data migration granting `:read` to every role and `:manage` to roles holding `fleet:manage`.
4. `FleetShoppingListPolicy`, modelled on `FleetInventoryPolicy`.

### Phase 2 — API
1. `GET/POST /fleets/{fleetSlug}/shopping-lists`, `GET/PUT/DELETE /fleets/{fleetSlug}/shopping-lists/{id}`. Create takes a `cartId` and copies its lines; update with a `cartId` replaces the lines.
2. `POST /fleets/{fleetSlug}/shopping-lists/{id}/copy`: into the member's own cart (`cartId`), or into a new list named after the fleet list. Answers with the cart.
3. Gated by the `shopping_cart` flag and `fleet` OAuth scopes. Schemas, jbuilder, and integration tests that generate the OpenAPI schema.

### Phase 3 — Frontend
1. A fleet page at `/fleets/:slug/shopping-lists`: list panels, a detail view with lines and an estimated total, and "Copy to my cart".
2. A modal to publish or replace from one of my lists, with name, description, visibility and squadrons.
3. A nav entry under Assets, shown with the flag and the read capability.
4. Locales for all 7 languages: privilege labels, nav, title, page strings, and Rails validation errors.

### Phase 4 — Tests
- Model, policy and integration tests, Vitest specs for the new components, and a Playwright spec for publish and copy.

## Intent Verification

- [ ] An officer publishes a cart list to the fleet; a member sees it and copies it into a new list of their own
- [ ] A squadron-only list is hidden from members outside the squadron, through both the API and the page
- [ ] Copying into an existing list sums quantities; pins are not copied
- [ ] Privileges appear with labels on the fleet roles page in every locale

## Key files

| File | Role |
|------|------|
| `app/models/fleet_inventory.rb` | Privileges and visibility pattern |
| `app/policies/fleet_inventory_policy.rb` | Policy pattern |
| `app/models/concerns/squadron_restrictable.rb` | Squadron visibility |
| `app/lib/carts/trip_plan.rb` | Prices the lines |
| `app/controllers/api/v1/cart_lists_controller.rb` | Cart endpoints to mirror |
| `app/frontend/frontend/components/Fleets/Logistics/InventoryModal/index.vue` | Visibility and squadron form |

## Not in scope (deferred)
- **Tracking who bought what**: rejected in the issue.
- **Subscription paywall**: logistics is premium-gated; shopping lists are left ungated pending a decision.

## Discovery Log

- **2026-10-26** Initial research and plan creation. `TripPlan` duck-types its lines, so fleet lines reuse it.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
