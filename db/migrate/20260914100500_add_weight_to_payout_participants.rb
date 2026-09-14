# frozen_string_literal: true

class AddWeightToPayoutParticipants < ActiveRecord::Migration[8.1]
  def change
    # A full share, so every ledger already open settles exactly as it did
    # before this column existed. Scale 2 matches the hundredths the settlement
    # already works in, which keeps the weighted division exact rather than
    # introducing a second rounding step of its own.
    add_column :payout_participants, :weight, :decimal, precision: 5, scale: 2, default: 1.0, null: false
  end
end
