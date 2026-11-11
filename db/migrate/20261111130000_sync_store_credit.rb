# frozen_string_literal: true

class SyncStoreCredit < ActiveRecord::Migration[8.1]
  def change
    # What the user's last hangar sync read from RSI; null until one does.
    add_column :users, :rsi_store_credit, :decimal, precision: 15, scale: 2

    # A plan without its own credit uses the synced one. Plans keep what they
    # hold, 0 included.
    change_column_null :hangar_plans, :starting_credit, true
    change_column_default :hangar_plans, :starting_credit, from: "0.0", to: nil
  end
end
