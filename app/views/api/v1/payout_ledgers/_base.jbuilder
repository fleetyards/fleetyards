# frozen_string_literal: true

json.id payout_ledger.id
json.subject_type payout_ledger.subject_type
json.subject_id payout_ledger.subject_id
json.status payout_ledger.status
json.notes payout_ledger.notes
json.settled_at payout_ledger.settled_at&.utc&.iso8601

json.partial! "api/shared/dates", record: payout_ledger
