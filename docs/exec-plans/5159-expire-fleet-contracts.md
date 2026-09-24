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

## What changed

### Phase 1 — Sweep job and schedule
1. `app/jobs/fleet_contracts/expire_job.rb` — the sweep
2. `config/sidekiq_schedule.yml` — `fleet_contracts_expire_job` every 15 minutes
3. `test/jobs/fleet_contracts/expire_job_test.rb` — past/future/no deadline, draft and closed states, the two races, an invalid contract, one failure not stopping the sweep, and an in-flight transfer still compensating into its source

## Intent Verification

- [x] **A past-deadline open or in-progress contract expires** — `expired_at` is stamped
- [x] **A future deadline, no deadline, a draft or a closed contract is left alone**
- [x] **Goods in flight still come home** — a pending linked transfer stays pending through the contract's expiry and returns its goods on its own expiry

## Key files

| File | Role |
|------|------|
| `app/jobs/fleet_contracts/expire_job.rb` | The sweep |
| `app/models/fleet_contract.rb` | `expire` event, `active` scope |
| `app/services/inventories/transfer_resolver.rb` | Where compensation into a source actually happens |
| `app/lib/contracts/fulfilment.rb` | The competing transition, same row lock |

## Progress
- [x] Phase 1
