# frozen_string_literal: true

json.cache! ["v1", payout_ledger] do
  json.partial!("api/v1/payout_ledgers/base", payout_ledger:)
end

# The totals are recomputed from the entries on every read, so they must not be
# stored in the fragment the ledger row keys -- an entry changing touches the
# ledger, but a participant joining does not change the ledger row at all.
settlement = Payouts::Settlement.new(payout_ledger)

json.participants_count payout_ledger.payout_participants.size
# What the profit is actually divided by. Worked out here rather than by
# summing the participants' weights on the client, for the reason the
# comment above gives about the totals: the arithmetic that decides money
# has one home, and floats are not it.
json.total_weight payout_ledger.payout_participants.sum(:weight)
json.entries_count payout_ledger.payout_entries.size
json.pending_review_count payout_ledger.payout_entries.review_pending.count
json.total_income settlement.total_income
json.total_expenses settlement.total_expenses
json.profit settlement.profit
