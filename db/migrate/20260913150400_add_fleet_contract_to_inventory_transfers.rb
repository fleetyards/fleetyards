# frozen_string_literal: true

# The link that makes a transfer count towards a contract.
#
# Nullable and `ON DELETE SET NULL`: the overwhelming majority of transfers have
# nothing to do with a contract, and deleting a contract must not take the
# movement of real goods out of either ledger with it.
class AddFleetContractToInventoryTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_transfers, :fleet_contract_id, :uuid
    add_foreign_key :inventory_transfers, :fleet_contracts,
      column: :fleet_contract_id, on_delete: :nullify
    add_index :inventory_transfers, :fleet_contract_id,
      where: "fleet_contract_id IS NOT NULL"
  end
end
