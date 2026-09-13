# frozen_string_literal: true

json.partial! "api/v1/payout_ledgers/payout_ledger", payout_ledger: @payout_ledger

json.participants do
  json.array! @payout_ledger.payout_participants.includes(:user).order(:created_at),
    partial: "api/v1/payout_participants/payout_participant", as: :payout_participant
end
