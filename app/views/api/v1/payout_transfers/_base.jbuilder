# frozen_string_literal: true

json.id payout_transfer.id
json.payout_ledger_id payout_transfer.payout_ledger_id
json.amount payout_transfer.amount
json.confirmed payout_transfer.confirmed?
json.confirmed_at payout_transfer.confirmed_at&.utc&.iso8601

json.from do
  json.partial! "api/v1/payout_participants/base", payout_participant: payout_transfer.from_participant
end

json.to do
  json.partial! "api/v1/payout_participants/base", payout_participant: payout_transfer.to_participant
end

json.partial! "api/shared/dates", record: payout_transfer
