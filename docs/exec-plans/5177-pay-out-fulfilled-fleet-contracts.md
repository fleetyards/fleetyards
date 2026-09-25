# Pay out a fulfilled fleet contract through the payout ledger

Working plan for #5177. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fulfilled fleet contract opens a payout ledger that pays its reward to the contractors by
`Contracts::Progress` weights, settling it moves the contract to `settled`, and settling any ledger
notifies its participants.

## Open questions
- None yet.

## What changed

### Phase 1 — Fleet participants
1. Migration: `payout_participants.fleet_id` (nullable FK), unique partial index
   `(payout_ledger_id, fleet_id) WHERE fleet_id IS NOT NULL`, check that exactly one of
   `user_id` / `fleet_id` / `name` is set.
2. `PayoutParticipant belongs_to :fleet, optional: true`; `display_name`/`guest?` account for it.
3. Participant jbuilder + `payouts/payout_participant.rb` schema expose a `fleet` ref.

### Phase 2 — Settlement strategies
1. `Payouts::Settlement` becomes a base (minor units, balances, min-cash-flow transfers, Σ net == 0).
2. `Payouts::Settlement::EqualShares` is today's `shares_by_participant_id`, unchanged.
3. `Payouts::Settlement::ContractPayout`: `share_c = reward × w_c / Σw`, fleet is the payer,
   expenses reimbursed first when `reimburse_expenses`.
4. `PayoutLedger#settlement` picks the strategy by subject type.

### Phase 2b — Expense review (all ledgers)
1. Migration: `payout_entries.review_status` (pending/approved/declined), `reviewed_by_id`,
   `reviewed_at`, `decline_reason`; existing rows backfilled `approved`.
2. Expenses by a non-manager land `pending`; by a manager `approved`; editing an approved expense
   resets it to `pending`. Income entries are always `approved`.
3. `approve` / `decline` member actions on entries, manager-only (`PayoutEntryPolicy`).
4. `Payouts::Settlement` counts approved expenses only; `settle!` refuses (409) while any is pending.
5. Entry schema + jbuilder expose the review fields; ledger UI shows pending/declined and the
   manager's Approve / Decline.

### Phase 3 — Contract as ledger subject
1. `SUBJECT_TYPES` gains `FleetContract`; `FleetContract has_one :payout_ledger, as: :subject`.
2. `seed_participants_from_subject!` seeds the fleet plus the contractors (weights from
   `Progress#weights`), and adds the `reward` income entry held by the fleet.
3. `PayoutLedgerPolicy` `read?`/`contribute?`/`manage?` branch delegates to `FleetContractPolicy`;
   only a `fulfilled` contract may create a ledger.
4. Routes `get/post "payouts"` on fleet contracts; `set_subject` handles `fleet_contract_slug`;
   gating keeps `check_tour_payouts_feature` + `require_fleet_subscription(:tours)` and adds
   `fleet_contracts` + `require_fleet_subscription(:contracts)` for contract subjects.
5. `reimburse_expenses: false` → expense entries refused (422) on that ledger.

### Phase 4 — `settled` state
1. Migration: `fleet_contracts.settled_at`.
2. AASM `settled` state + `settle` event (`fulfilled → settled`); `scope :closed` includes it.
3. `PayoutLedger#carry_status_to_subject` handles contracts; AASM `reopen` (`settled → fulfilled`).
4. `FleetContractStateEnum` gains `settled`; oasdiff-ignore entry.

### Phase 5 — Settle notifications
1. `fleet_contract_settled` and `payout_ledger_settled` in the `Notification` enum + `TYPES`.
2. Notify user participants from `PayoutLedger#settle!` (after commit), linking to the subject.
3. Strings in all 7 `notifications.yml`, `labels.notificationTypes.*` in all 7 `labels.json`,
   `useNotificationActions.ts` action.

### Phase 6 — Frontend
1. Contract page: "open payout ledger" on a fulfilled contract, embedded `PayoutLedger` component,
   participant list renders fleet participants.
2. `ContractStatePill` and filters know `settled`.

### Phase 7 — Regenerate schemas and clients
1. `swagger/v1/schema.yaml`, `asyncapi/cable/v1/schema.yaml`, fyApi/fyCable clients.

## Intent Verification

- [ ] **A fulfilled contract can open a payout ledger that uses the contract's reward divide** —
  create on a fulfilled contract returns 201; balances show each contractor's `reward × w_c / Σw`;
  a non-fulfilled contract is refused.
- [ ] **Settling the ledger moves the contract to `settled`** — `settle` on the ledger leaves the
  contract `settled` with `settled_at` set.
- [ ] **Participants get a notification when any payout ledger settles** — settling an event, tour
  and contract ledger each creates a notification for every user participant.
- [ ] **Contractor expenses are reviewed** — a contractor's expense is pending and excluded until a
  manager approves it; a declined one never counts; settling with a pending expense returns 409.
- [ ] **Reopen reverts the contract** — reopening the ledger leaves the contract `fulfilled`.
- [ ] **Event and tour settlement unchanged** apart from expense review — `test/lib/payouts/settlement_test.rb` passes untouched.

## Key files

| File | Role |
|------|------|
| `app/models/payout_ledger.rb` | Subject types, seeding, `settle!`, `carry_status_to_subject` |
| `app/models/payout_participant.rb` | Party columns and validation |
| `app/lib/payouts/settlement.rb` | Split into base + strategies |
| `app/lib/contracts/progress.rb` | Per-contractor weights |
| `app/models/fleet_contract.rb` | AASM `settled` |
| `app/controllers/api/v1/payout_ledgers_controller.rb` | `set_subject`, gating |
| `app/controllers/concerns/payout_ledger_scoped.rb` | Gating for nested controllers |
| `app/policies/payout_ledger_policy.rb` | Contract branch |
| `config/routes/api/fleets_routes.rb` | Contract `payouts` routes |
| `app/models/notification.rb` | New types |
| `app/api_components/v1/schemas/enums/fleet_contract_state_enum.rb` | `settled` |
| `app/frontend/frontend/pages/fleets/[slug]/contracts/[contract].vue` | Ledger UI |
| `app/frontend/frontend/components/Payouts/PayoutLedger/index.vue` | Reused ledger component |

## Not in scope (deferred)
- **Fleet participants on event/tour ledgers** — the column allows it, but no UI adds one.

## Discovery Log

- **2026-09-25** Initial research and plan creation. Design basis is the deleted 4888 plan D5–D7
  (`git show 208983eefe^:docs/exec-plans/4888-fleet-contracts.md`).

## Progress
- [ ] Phase 1 — Fleet participants
- [ ] Phase 2 — Settlement strategies
- [ ] Phase 2b — Expense review
- [ ] Phase 3 — Contract as ledger subject
- [ ] Phase 4 — `settled` state
- [ ] Phase 5 — Settle notifications
- [ ] Phase 6 — Frontend
- [ ] Phase 7 — Regenerate schemas and clients
