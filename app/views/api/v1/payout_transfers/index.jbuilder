# frozen_string_literal: true

json.array! @payout_transfers, partial: "api/v1/payout_transfers/payout_transfer", as: :payout_transfer
