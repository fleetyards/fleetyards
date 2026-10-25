# frozen_string_literal: true

class AddRewardTypeToFleetContracts < ActiveRecord::Migration[8.1]
  def up
    # The default is for the release still serving while this migrates, which
    # creates contracts without knowing the column; the model ignores it and
    # requires a choice. Fixed, because that is what those contracts mean.
    add_column :fleet_contracts, :reward_type, :integer, default: 0, null: false

    # Every contract so far paid a fixed total, and one paying nothing could only
    # say so with a zero.
    execute <<~SQL.squish
      UPDATE fleet_contracts SET reward_type = 2 WHERE reward = 0
    SQL

    # Only the half the old release cannot break: it still saves a fixed reward
    # of 0. The model refuses that for new saves.
    add_check_constraint :fleet_contracts, "reward_type <> 2 OR reward = 0",
      name: "fleet_contracts_reward_matches_type"
  end

  def down
    remove_check_constraint :fleet_contracts, name: "fleet_contracts_reward_matches_type"
    remove_column :fleet_contracts, :reward_type
  end
end
