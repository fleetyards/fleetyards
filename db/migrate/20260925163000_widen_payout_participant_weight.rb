# frozen_string_literal: true

class WidenPayoutParticipantWeight < ActiveRecord::Migration[8.1]
  # A contractor's weight is their share of what was delivered, and one crate
  # out of a large order is far below a hundredth of a percent. Widening only,
  # so every stored weight keeps its value.
  def up
    change_column :payout_participants, :weight, :decimal, precision: 9, scale: 6, default: "1.0", null: false
  end

  def down
    change_column :payout_participants, :weight, :decimal, precision: 5, scale: 2, default: "1.0", null: false
  end
end
