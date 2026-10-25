# frozen_string_literal: true

class AddPayerToPayoutParticipants < ActiveRecord::Migration[8.1]
  def up
    add_column :payout_participants, :payer, :boolean, default: false, null: false

    # Every payer so far is a fleet paying its contract's reward.
    execute "UPDATE payout_participants SET payer = TRUE WHERE fleet_id IS NOT NULL"
  end

  def down
    remove_column :payout_participants, :payer
  end
end
