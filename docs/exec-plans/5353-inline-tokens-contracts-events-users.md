# Inline tokens for fleet contracts, fleet events and users

Working plan for #5353. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`[*contract:FID/Title*]`, `[*event:FID/Title*]` and `[*user:handle*]` link, with a hover card, for readers allowed to see the target, and read as plain text for everyone else.

## Open questions
- none

## What changed

### Phase 1 — Backend resolution
1. `Catalogue::RestrictedTokenResolver`: contract, event and user tokens, resolved per reader (policy `show?`, the feature flag, the fleet subscription, accepted membership in a kept fleet; hangar readability for users).
2. `Catalogue::TokenResolver` takes a `reader:` and hands those three prefixes over; a prefixed search query narrows to its type.
3. Lookup and search pass the reader; an OAuth token without `fleet`/`fleet:read` resolves no contract or event.
4. Match gains `fleetSlug`; the type enum gains `FleetContract`, `FleetEvent`, `User`.
5. `MarkdownPlainText` reads the new prefixes as their title or handle.

### Phase 2 — Frontend
1. Token grammar, names and icons for the three prefixes.
2. Routes: `fleet-contract`, `fleet-event`, `hangar-public`.
3. Hover cards for contract, event and user.
4. The lookup cache is dropped on sign-in and sign-out.
5. Editor suggestion labels in all seven locales.

### Phase 3 — Tests
1. Resolver tests for every access rule (signed out, non-member, missing access, squadron, draft, feature, subscription, hangar privacy, friends).
2. Integration tests on lookup and search, signed in and with a narrow OAuth scope.
3. Frontend specs for names, routes and the popover.

## Intent Verification

- [ ] **Contract and event tokens link for readers who may see them** — resolver + integration tests
- [ ] **User tokens link to the hangar when readable** — resolver tests
- [ ] **Autocomplete offers the writer's fleets' contracts/events, friends and fleet-mates** — search tests
- [ ] **Every access rule tested** — resolver tests

## Key files

| File | Role |
|------|------|
| `app/services/catalogue/token_resolver.rb` | Token parsing, lookup, search |
| `app/services/catalogue/restricted_token_resolver.rb` | Reader-dependent tokens |
| `app/controllers/api/v1/catalogue_controller.rb` | Lookup and search endpoints |
| `app/frontend/shared/utils/CatalogueTokens.ts` | Token grammar on the frontend |
| `app/frontend/frontend/components/CatalogueItemPopover/index.vue` | Hover cards |

## Not in scope (deferred)
- **Rewriting tokens on rename** — open in the issue.
- **Mention notifications** — open in the issue.

## Discovery Log

- **2026-10-01** Initial research. The event page enforces neither `officers` nor draft visibility; only the policy, squadron narrowing, the `fleet_mission_builder` flag and the fleet subscription. Contract titles are unique per fleet, event titles are not.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
