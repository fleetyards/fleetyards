# frozen_string_literal: true

class AddFleetToPayoutParticipants < ActiveRecord::Migration[8.1]
  def change
    add_reference :payout_participants, :fleet, type: :uuid, foreign_key: true

    add_index :payout_participants, %i[payout_ledger_id fleet_id],
      unique: true,
      where: "fleet_id IS NOT NULL",
      name: "index_payout_participants_unique_fleet_per_ledger"

    add_check_constraint :payout_participants,
      "num_nonnulls(user_id, fleet_id) <= 1",
      name: "payout_participants_one_party"
  end
end
