# frozen_string_literal: true

json.id payout_entry.id
json.payout_ledger_id payout_entry.payout_ledger_id
json.payout_participant_id payout_entry.payout_participant_id
json.entry_type payout_entry.entry_type
json.amount payout_entry.amount
json.description payout_entry.description
json.notes payout_entry.notes
json.occurred_at payout_entry.occurred_at&.utc&.iso8601

json.participant do
  json.partial! "api/v1/payout_participants/base", payout_participant: payout_entry.payout_participant
end

json.partial! "api/shared/dates", record: payout_entry
