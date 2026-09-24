# Expire fleet contracts at their deadline

## Goal
Close fleet contracts whose deadline has passed while they were still `open` or `in_progress`.

## Context
`FleetContract` has a `deadline` column and an `expire` event (`open`/`in_progress` -> `expired`), but nothing fired it, so a contract past its deadline stayed on the board indefinitely. `Inventories::ExpireTransfersJob` already sweeps pending transfers by `expires_at`; contracts needed the same sweep.

Resolves #5159

## Decisions

### D1 — A scheduled sweep, every 15 minutes
`FleetContracts::ExpireJob` runs from `config/sidekiq_schedule.yml`, production only, like the transfer sweep. A deadline is a time members plan around, so the sweep runs far more often than the daily transfer one; the query only reads the active contracts.

### D2 — Expiry moves no goods, the same as cancelling
Cancelling a contract only changes its state. Compensation back into a source is a property of *transfers*: a declined, cancelled or expired transfer writes a deposit back into its source through `Inventories::TransferResolver`, and `Contracts::Progress` reads the ledger that produces. The expiry keeps that parity: a delivery already accepted stays in the destination, and a transfer still in flight resolves on its own. `Contracts::TransferLink` refuses any new transfer against a contract that is not in progress, so an expired contract takes no further deliveries.

### D3 — Lock and re-check, skip validations
`whiny_transitions: false` makes a losing transition fail silently, and the sweep races the final delivery (`Contracts::Fulfilment` takes the same row lock), a manager cancelling, and a deadline being moved out. Each contract is expired inside `with_lock`, re-checking `may_expire?` and the deadline after the reload. The save skips validations so a contract whose destination inventory was deleted still closes. Each contract is handled on its own; an error is reported to AppSignal and the sweep continues.

### D4 — A late delivery still completes an expired contract
A transfer still pending at the deadline can be accepted afterwards, and the goods it lands are in the destination like any other. `fulfil` now transitions from `expired` as well as `in_progress`, and `Contracts::Fulfilment` runs for both, so the delivery that lands the last line moves the contract `expired -> fulfilled` and announces `fleet_contract.fulfilled` as usual (the crew on an expired contract keep their accepted seats, so they are told too). A part delivery leaves it `expired`; there is no partial state, and `Contracts::Progress` already counts accepted deliveries whatever the state. A cancelled contract is never fulfilled.

A manager may also force-fulfil an expired contract (`FleetContractPolicy#fulfil?`, and the button on the detail page). Forcing exists to make a part-delivered job payable, and an expired part-delivered job is the same case; the model event already allows it, so the policy mirrors it.

`expired_at` is kept on fulfilment: it records that the deadline was missed, and `fulfilled_at` records when the goods completed it.

The delivered bar no longer greys out an expired contract, so its partial delivery shows. Draft and cancelled stay quiet.

## Discovery log
- Accepting a transfer (`Inventories::TransferResolver#accept`) does not look at the contract's state, so a delivery in flight at the deadline could land after expiry and fill every line while the contract stayed `expired`. Only `Contracts::TransferLink` checks the state, and only when a transfer is filed. Led to D4.

## What changed

### Phase 1 — Sweep job and schedule
1. `app/jobs/fleet_contracts/expire_job.rb` — the sweep
2. `config/sidekiq_schedule.yml` — `fleet_contracts_expire_job` every 15 minutes
3. `test/jobs/fleet_contracts/expire_job_test.rb` — past/future/no deadline, draft and closed states, the two races, an invalid contract, one failure not stopping the sweep, and an in-flight transfer still compensating into its source

### Phase 2 — Late deliveries
1. `app/models/fleet_contract.rb` — `fulfil` from `expired`
2. `app/lib/contracts/fulfilment.rb` — runs for an expired contract
3. `app/policies/fleet_contract_policy.rb`, `app/frontend/frontend/pages/fleets/[slug]/contracts/[contract].vue` — force-fulfil an expired contract
4. `app/frontend/frontend/components/Fleets/Contracts/ContractDeliveredBar/index.vue` — expired is no longer a quiet state
5. Tests in `test/lib/contracts/fulfilment_test.rb`, `test/jobs/fleet_contracts/expire_job_test.rb`, `test/integration/api/v1/fleet_contracts_test.rb` and the bar's spec

## Intent Verification

- [x] **A past-deadline open or in-progress contract expires** — `expired_at` is stamped
- [x] **A future deadline, no deadline, a draft or a closed contract is left alone**
- [x] **Goods in flight still come home** — a pending linked transfer stays pending through the contract's expiry and returns its goods on its own expiry
- [x] **A late delivery completing every line fulfils an expired contract** — `expired_at` kept, `fulfilled_at` stamped
- [x] **A late part delivery leaves it expired, and counts** — the delivered bar shows it
- [x] **A cancelled contract is never fulfilled by a late delivery**

## Key files

| File | Role |
|------|------|
| `app/jobs/fleet_contracts/expire_job.rb` | The sweep |
| `app/models/fleet_contract.rb` | `expire` event, `active` scope |
| `app/services/inventories/transfer_resolver.rb` | Where compensation into a source actually happens |
| `app/lib/contracts/fulfilment.rb` | The competing transition, same row lock |

## Progress
- [x] Phase 1
- [x] Phase 2
