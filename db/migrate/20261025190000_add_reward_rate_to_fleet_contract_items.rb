# frozen_string_literal: true

class AddRewardRateToFleetContractItems < ActiveRecord::Migration[8.1]
  def up
    # What a per-unit contract pays for each SCU or unit delivered against this
    # line. Per line because goods differ in worth: one rate across a contract
    # asking for gold and for scrap overpays one or underpays the other.
    add_column :fleet_contract_items, :reward_rate, :decimal, precision: 15, scale: 2

    add_check_constraint :fleet_contract_items, "reward_rate IS NULL OR reward_rate > 0",
      name: "fleet_contract_items_reward_rate_positive"

    # A per-unit contract held its one rate on the contract. Every line takes
    # it, before the model starts clearing the contract's own amount.
    execute <<~SQL.squish
      UPDATE fleet_contract_items SET reward_rate = fleet_contracts.reward
      FROM fleet_contracts
      WHERE fleet_contracts.id = fleet_contract_items.fleet_contract_id
        AND fleet_contracts.reward_type = 1 AND fleet_contracts.reward > 0
    SQL
  end

  def down
    remove_check_constraint :fleet_contract_items, name: "fleet_contract_items_reward_rate_positive"
    remove_column :fleet_contract_items, :reward_rate
  end
end
