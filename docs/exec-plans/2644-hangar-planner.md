# Hangar Planner

Working plan for [#2644](https://github.com/fleetyards/fleetyards/issues/2644). Product decisions live in the issue body. Delete this plan before the PR merges.

## Goal

Let users build a plan of slots (open, decided or undecided between several candidate ships), compare the decided slots with the current hangar, and plan melts and acquisition steps using available ships, owned RSI upgrades, buybacks and purchases.

## Open questions

All resolved; see the issue body.

## What changed

### Phase 1 — Product scope and domain foundation

1. Resolve the issue's open questions and record decisions there.
2. Add independent plan/slot/candidate persistence with labels and quantities, separate acquisition routes and melt selections, ordered upgrade steps, decimal prices and baseline snapshots; do not use Vehicle records for plan items.
3. Add factories, owner authorization and a registered feature flag.
4. Support starting from purchased hangar vehicles, wishlist, empty state and another plan.

### Phase 2 — Actions and calculations

1. Match decided slot quantities against current ships; implement keep, buy, melt, owned RSI CCUs, chained CCUs and buyback operations, including in-game acquisition. Keep intermediate steps separate from target ships.
2. Support item paints, modules and upgrade kits, and compute bundled craft and loaners for display.
3. Calculate new spend, melt credits, net cost and remaining starting credit, as a min–max range while slots are undecided; expose missing prices and unavailable models.
4. Validate upgrade chains, source ownership and available resource quantities, with explicit override handling. Show unresolved acquisition gaps.
5. Test financial operations, unknown prices and invalid or duplicated source consumption.

### Phase 3 — API, comparisons and drift

1. Write Minitest integration tests before endpoint implementation, using named OpenAPI components.
2. Add plan/item CRUD, duplication, ordering and calculation endpoints with owner policy checks.
3. Share metrics calculation appropriately with live hangar stats and verify seeded-plan parity.
4. Add live-versus-plan and plan-versus-plan comparisons, source and price drift, and explicit rebase behavior.
5. Regenerate schemas and frontend clients.

### Phase 4 — Planner interface and sharing

1. Add feature-gated list, editor and comparison pages under /hangar/plans.
2. Reuse suitable model selection and display components while keeping planner state independent from live hangar mutations.
3. Start the editor with the slot list (add slots, add or remove candidates, pick one); add side-by-side candidate views for undecided slots, comparison with the current hangar, melt selections, owned-upgrade and buyback source selection, acquisition chain editing, cost summaries and drift warnings.
4. Implement private-by-default, per-plan read-only share tokens and revocation.
5. Translate every supported locale by hand and test route gating and editor behavior.

### Phase 5 — Verification and delivery

1. Exercise create target list → compare current hangar → select melts and owned-upgrade/buyback acquisition steps → review gaps and costs in an end-to-end test.
2. Verify ownership isolation, sharing permissions, flag behavior and unchanged real hangar state.
3. Run Ruby formatting, frontend linting, type checking and relevant test suites.
4. Move durable findings to docs/findings, resolve deferred work into issues or drop it, and remove this plan before merge.

## Intent Verification

- [ ] Plans use separate storage and do not trigger Vehicle callbacks.
- [ ] Users can create open, decided and undecided slots and edit slot quantities independently of acquisition routes and intermediate models.
- [ ] All four starting modes preserve supported item configuration.
- [ ] Comparison identifies keep/melt/upgrade candidates and missing target ships.
- [ ] Acquisition can use owned RSI CCUs and buyback ships/upgrades without exceeding resource quantities.
- [ ] Unresolved acquisition gaps are visible.
- [ ] Keep, buy, melt, CCU chains and buyback produce correct decimal cost summaries.
- [ ] Missing prices and unavailable models are clearly identified.
- [ ] A plan seeded from the hangar yields matching metrics.
- [ ] Comparisons and drift identify additions, removals, upgrades and changed prices.
- [ ] Rebase behavior follows the recorded product decision.
- [ ] Owner-only editing and optional read-only sharing are enforced.
- [ ] Planner UI is feature-gated and fully translated.
- [ ] The target list → comparison → melt/acquisition selection flow passes end to end.

## Key files

| File | Role |
|------|------|
| app/models/vehicle.rb | Live hangar callbacks and configuration to inspect without reusing planner storage |
| app/models/buyback_pledge.rb | Buyback sources and upgrade price calculation |
| app/models/hangar_pledge_item.rb | Existing owned CCUs and pledge-level values |
| app/models/model.rb | Catalogue prices, loaners and metrics |
| app/controllers/api/v1/hangar_stats_controller.rb | Existing metrics and parity baseline |
| app/controllers/api/v1/hangar_groups_controller.rb | Owner-scoped API pattern |
| config/routes/api/hangar_routes.rb | Hangar API routing |
| app/controllers/concerns/hangar_share_token_concern.rb | Sharing pattern; plans require separate tokens |
| app/api_components/ | Named request, response and enum schemas |
| config/feature_flags.yml | Feature registry |
| app/frontend/frontend/pages/hangar/routes.ts | Feature-gated planner routes |
| app/frontend/frontend/components/Hangar/ | Existing hangar display and editing patterns |
| app/frontend/translations/ | Supported locale translations |
| test/integration/api/v1/hangar_groups_test.rb | OpenAPI-backed integration test pattern |

## Not in scope (deferred)

Cheapest-value route optimization and recommendations are follow-up work per the issue decision. Create a separate typed issue before this branch merges. Suggestion mode (questionnaire → slots → candidates, roles mapped from `models.focus`) is #5860. Fleet visibility and cable editing are excluded by the issue's v1 scope.

## Discovery Log

- **2026-10-19:** Created worktree under worktrees/2644-hangar-planner from origin/main and ran bin/setup.
- Vehicle callbacks generate related craft, synchronize hangar state and broadcast changes; planner persistence must remain independent.
- Vehicle records do not retain paid price or melt value. Existing hangar metrics coerce missing catalogue prices to zero; planner financial calculations must preserve unknown values.
- Buyback upgrade prices use current catalogue differences. Existing owned CCUs resolve model names from text rather than durable model references.
- Historical drift requires snapshots as well as source links, including when source vehicles are deleted.
- GitHub CLI could publish the branch but failed to attach it as a linked development branch (API returned empty branch name).

- **2026-10-20:** Reworked the concept around slots; decisions recorded in the issue body. `models.focus` is free text with 30+ combat variants alone (case, spacing, `Gunship`/`Gun Ship`, compound `A / B`), so suggestions need a role mapping (#5860).

- **2026-10-20:** `bin/rails db:migrate` is blocked in this mode; `db/schema.rb` was written by hand and the test DB loaded from it. The migration has not been run against a dev database.
- `to_model` is an Active Record method, so upgrade steps name their associations `origin_model` / `target_model` over the `from_model_id` / `to_model_id` columns.
- Model facts (`cargo`, `crew`) read the build, so every ship in a plan payload preloads `HangarPlans::MODEL_PRELOAD`; without it the editor grew by 12 queries per slot.
- Slots gained a description and a filter set in the catalogue's filter terms; the ship picker opens on them, candidates outside are marked.

## Progress

- [x] Fetch issue, assign owner and move project status to In Progress.
- [x] Create and publish feat/2644-hangar-planner.
- [x] Create worktree, run environment setup and research existing patterns.
- [x] Create implementation plan.
- [x] Resolve open product questions.
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [ ] Phase 5 (PR, review)
