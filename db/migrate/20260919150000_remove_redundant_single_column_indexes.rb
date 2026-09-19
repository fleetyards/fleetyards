# frozen_string_literal: true

class RemoveRedundantSingleColumnIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Every index below sits on the leading column of a composite index on the
  # same table, which answers the same lookups -- so the narrow one only costs
  # write time and disk.
  #
  # Nine drops outside a transaction: an interrupted run records nothing and
  # starts again from the first, so each has to tolerate having already gone.
  def change
    remove_index :fleet_contract_assignments, column: :fleet_contract_id,
      name: "index_fleet_contract_assignments_on_fleet_contract_id", algorithm: :concurrently, if_exists: true
    remove_index :fleet_contract_items, column: :fleet_contract_id,
      name: "index_fleet_contract_items_on_fleet_contract_id", algorithm: :concurrently, if_exists: true
    remove_index :fleet_contracts, column: :fleet_id,
      name: "index_fleet_contracts_on_fleet_id", algorithm: :concurrently, if_exists: true
    remove_index :fleet_inventory_positions, column: :fleet_inventory_id,
      name: "index_fleet_inventory_positions_on_fleet_inventory_id", algorithm: :concurrently, if_exists: true
    remove_index :hardpoint_builds, column: :hardpoint_id,
      name: "index_hardpoint_builds_on_hardpoint_id", algorithm: :concurrently, if_exists: true
    remove_index :imports, column: :type,
      name: "index_imports_on_type", algorithm: :concurrently, if_exists: true
    remove_index :inventory_positions, column: :inventory_id,
      name: "index_inventory_positions_on_inventory_id", algorithm: :concurrently, if_exists: true
    remove_index :model_module_builds, column: :model_module_id,
      name: "index_model_module_builds_on_model_module_id", algorithm: :concurrently, if_exists: true
    remove_index :payout_entries, column: :payout_ledger_id,
      name: "index_payout_entries_on_payout_ledger_id", algorithm: :concurrently, if_exists: true
  end
end
