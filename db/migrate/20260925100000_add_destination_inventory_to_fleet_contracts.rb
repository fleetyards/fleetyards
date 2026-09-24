# frozen_string_literal: true

class AddDestinationInventoryToFleetContracts < ActiveRecord::Migration[8.1]
  def change
    add_reference :fleet_contracts, :destination_inventory, type: :uuid, index: true,
      foreign_key: {to_table: :inventories, on_delete: :nullify}

    # At most one rather than exactly one: deleting either inventory nulls its
    # column, and the contract row has to survive that.
    add_check_constraint :fleet_contracts,
      "num_nonnulls(destination_fleet_inventory_id, destination_inventory_id) <= 1",
      name: "fleet_contracts_single_destination"
  end
end
