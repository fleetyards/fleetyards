# Hangar planner: start and end pickers in the flow rows

Issue: not filed yet (the decisions are recorded in the draft issue body handed over with this branch).

## Phases

1. **Backend: a pairing without a route**
   - `HangarPlanAcquisition`: an empty chain may start elsewhere than the slot's ship (`route_complete?` false); a chain with steps still has to end on it. The update accepts `candidateId`, and the slot quantity is checked when the candidate changes.
   - `Comparison`: an owned pairing without a route is `unrouted`, with the slot's ship as its target.
   - `Summary`: an unrouted pairing is an unresolved unit, and its price is not counted.
   - JSON + schema: `routeComplete` on the acquisition, `candidateId` on the update input, the new vehicle status.
2. **Frontend: pickers in the rows**
   - `HangarFlow`: the left card opens a start picker, the right card an end picker. The middle plans or edits the route.
   - A composable that turns picks into acquisition creates, updates and destroys.
   - The decision buttons fold into the pickers; melt, change and pending stay in the middle.
   - Readiness and the tallies count unrouted pairings.
3. **Translations, specs, PR**

## Key files

- `app/models/hangar_plan_acquisition.rb`
- `app/lib/hangar_plans/{comparison,summary}.rb`
- `app/controllers/api/v1/hangar_plan_acquisitions_controller.rb`
- `app/frontend/frontend/components/Hangar/Planner/HangarFlow/index.vue`
- `app/frontend/frontend/composables/useHangarPlanDecisions.ts`

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3 (translations, specs); PR still to open

## Discovery log

- RSI sells no CCU for a ship pledged at $1000 or more (decided mid-branch):
  `Model#upgradable?`, validated on every upgrade step, exposed as
  `upgradable` on the plan's models. "Limited" ships are left out: no data
  marks them yet.
- Starts are offered only below the target's price (an undecided slot: below
  its cheapest ship), or as the same model.
- An undecided slot takes a start too: the picker asks which of its ships the
  start becomes and settles the slot on it, as "Choose" in the slot modal does.
- A non-upgradable ship marked "should change" keeps that mark but offers only
  melt or back to undecided.
- The e2e spec was only re-pointed at the new middle button; CI runs it.
