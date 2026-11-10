# Fleet contracts based on a catalogue mission, with its blueprint rewards

Working plan for #6272. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fleet can post a `mission` contract that points at a catalogue `GameMission`, shows that mission's blueprint rewards, and is marked complete by its author or a contract manager.

## What changed

### Phase 1 — Backend
1. Migration: `fleet_contracts.game_mission_id` (uuid FK), check constraints: mission kind ⇔ game mission; mission has no destination; mission is never per_unit.
2. `FleetContract`: kind `mission: 3`, `belongs_to :game_mission`, validations, `ready_to_publish?`, `display_title`, no items.
3. `FleetContractItem` refuses a mission contract; `Contracts::TransferLink` refuses it.
4. Policy: `fulfil?` also for the author of a mission contract; permit `game_mission_id`.
5. Views/schemas: `gameMission` link on the contract, `missionBlueprints` on the detail; input `gameMissionId`.
6. Fleet `mission_contract_cover` attachment.
7. Locales (7) for generated titles.

### Phase 2 — Frontend
1. Form: kind mission → mission picker, no destination, no per-unit.
2. new/edit pages: mission picker instead of items.
3. Detail page: mission panel with blueprints, no route/delivered panels, complete button for the author.
4. Kind label, cover stand-in, settings cover field; locales (7).

## Intent Verification
- [ ] A mission contract can be created, published, claimed and marked complete by its author; payout splits equally over the crew.
- [ ] The detail page shows the mission and its blueprint rewards from the served build.
- [ ] Goods kinds are unchanged.

## Discovery Log
- **2026-11-10** Initial research and plan creation

## Progress
- [ ] Phase 1
- [ ] Phase 2
