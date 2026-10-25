# frozen_string_literal: true

class AddRewardRateToFleetContractItems < ActiveRecord::Migration[8.1]
  def change
    # What a per-unit contract pays for each SCU or unit delivered against this
    # line. Per line because goods differ in worth: one rate across a contract
    # asking for gold and for scrap overpays one or underpays the other.
    add_column :fleet_contract_items, :reward_rate, :decimal, precision: 15, scale: 2

    add_check_constraint :fleet_contract_items, "reward_rate IS NULL OR reward_rate > 0",
      name: "fleet_contract_items_reward_rate_positive"
  end
end
