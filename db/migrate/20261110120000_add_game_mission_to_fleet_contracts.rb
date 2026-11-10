# frozen_string_literal: true

class AddGameMissionToFleetContracts < ActiveRecord::Migration[8.1]
  def up
    add_reference :fleet_contracts, :game_mission, type: :uuid, foreign_key: true, index: true

    add_check_constraint :fleet_contracts, "(kind = 3) = (game_mission_id IS NOT NULL)",
      name: "fleet_contracts_game_mission_only_for_mission"

    # A mission is run, not delivered: nothing lands anywhere and there is no
    # quantity a rate could be paid on.
    add_check_constraint :fleet_contracts,
      "kind <> 3 OR (destination_fleet_inventory_id IS NULL AND destination_inventory_id IS NULL AND reward_type <> 1)",
      name: "fleet_contracts_mission_has_no_goods"
  end

  def down
    remove_check_constraint :fleet_contracts, name: "fleet_contracts_mission_has_no_goods"
    remove_check_constraint :fleet_contracts, name: "fleet_contracts_game_mission_only_for_mission"
    remove_reference :fleet_contracts, :game_mission
  end
end
