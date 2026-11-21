# Import owned blueprints from Star Citizen game logs

Working plan for #6447. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A user drops their LIVE folder on `/hangar/blueprints` and the blueprints they received in game are marked owned after one review step.

## What changed

### Phase 1 — API
1. `PUT /hangar/blueprint-imports/match` — names in, per name the blueprints it can mean (slug, name, owned, wanted). No write.
2. `PUT /hangar/blueprint-imports` — slugs (+ names nothing matched) in; marks owned, promotes wanted, records `Imports::BlueprintLogImport`; returns counts + importId.
3. Name matching: case, quote style and whitespace insensitive, against every blueprint (retired too).
4. Import type added to `ImportTypeEnum` (public + admin), user import partial, result details (imported / unchanged / missing).

### Phase 2 — Frontend
1. Pure log parser (`Received Blueprint:` notification lines, channel from the `Executable:` header) with Vitest coverage.
2. Modal from the blueprints page: drop folder / pick files → parse locally → match → review (new, already owned, ambiguous pick, unmatched) → import.
3. Translations in every locale; import type label.

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/hangar_blueprint_imports_controller.rb` | match + import |
| `app/models/imports/blueprint_log_import.rb` | recorded run |
| `app/models/blueprint.rb` | name normalisation / lookup |
| `app/frontend/frontend/utils/blueprintLog.ts` | log parser |
| `app/frontend/frontend/components/Blueprints/LogImport/` | modal |
| `app/frontend/shared/components/DirectUpload/directoryFiles.ts` | folder drop walking (reused) |

## Discovery Log

- **2026-11-21** Strata parses `<SHUDEvent_OnNotification> Added notification "Received Blueprint: <name>: " [id] to queue` client-side in a worker, channel from `Executable:` in the log header (LIVE/HOTFIX). Catalogue `Blueprint#name` is the crafted item's display name; 4 names are shared by two blueprints (colourways), so ambiguity needs a pick. `Imports::BuybackSync` is the precedent for a client-parsed, request-bound recorded import.

## Progress
- [ ] Phase 1
- [ ] Phase 2
