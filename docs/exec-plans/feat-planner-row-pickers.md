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

- CCU availability comes from evidence, not price (the $1000 rule let the
  Pioneer through and blocked Kraken to Kraken Privateer): `Rsi::CcuCatalogue`
  records each ship any synced hangar CCU or buy-back upgrade led out of or
  into (3386 titles, 228 targets in the production dump), the pledge store
  loader records what is on sale today, and an admin override wins. A ship
  with no evidence is "unknown" for 90 days after it is listed, then "none".
  Only store-bought steps are checked; held and bought-back upgrades count
  regardless. The catalogue runs daily at 20:30; the first production run
  happens on its own after deploy.
- RSI's upgrade tool lists its ships without a login, but which targets a
  ship reaches needs an account, so it is not used.
- Starts are offered only below the target's price, or as the same model. For
  an undecided slot, anything that reaches one of its ships, marked with the
  ships it rules out.
- Buy-backs sit in the start list beside hangar ships and the store, with
  source and status chips on top; only in-game starts and step-by-step routes
  still go through the route editor.
- Adding a slot asks only for its name; filters are saved from the slot's
  ship picker.
- An undecided slot takes a start without deciding anything: it is saved on
  the ship it comes closest to and moves to whichever ship the slot keeps
  (`HangarPlanSlot#choose!`, `#remove_candidate!`). Asking for the ship right
  after the start was tried first and rejected: a start must not force a
  decision.
- Ships already kept as they are are no starts; the slot dialog links to the
  compare page while it holds more than one ship.
- A non-upgradable ship marked "should change" keeps that mark but offers only
  melt or back to undecided.
- The e2e spec was only re-pointed at the new middle button; CI runs it.
- The route editor only builds the chain of upgrades between a start and an
  end the row already picked, and is offered only between two different ships
  upgrades can join. Picking a start, the build-from-the-target mode and the
  start lists left it; in-game starts moved into the row's start list.
