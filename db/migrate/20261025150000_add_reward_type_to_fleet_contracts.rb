# frozen_string_literal: true

class AddRewardTypeToFleetContracts < ActiveRecord::Migration[8.1]
  def up
    add_column :fleet_contracts, :reward_type, :integer

    # Every contract so far paid a fixed total, and one paying nothing could only
    # say so with a zero.
    execute <<~SQL.squish
      UPDATE fleet_contracts SET reward_type = CASE WHEN reward > 0 THEN 0 ELSE 2 END
    SQL

    change_column_null :fleet_contracts, :reward_type, false

    add_check_constraint :fleet_contracts,
      "(reward_type = 2 AND reward = 0) OR (reward_type <> 2 AND reward > 0)",
      name: "fleet_contracts_reward_matches_type"
  end

  def down
    remove_check_constraint :fleet_contracts, name: "fleet_contracts_reward_matches_type"
    remove_column :fleet_contracts, :reward_type
  end
end
